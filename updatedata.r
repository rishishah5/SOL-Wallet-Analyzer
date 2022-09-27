source("/Users/rishi-shah/data_science/util/util_functions.R")
rishi<- QuerySnowflake("with mints as (
  SELECT mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,'resell' as type, labels.label,
 profitt.bought_price,profitt.sold_for,
   profitt.profit
from profitt
inner join solana.core.dim_labels labels on profitt.mint = labels.address),

  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select labels.label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price, 
  labeled.bought_for, 
  floor_price.floor_price - labeled.bought_for as net_worth_of_holds
from labeled
inner join floor_price on  labeled.label = floor_price.label)

,



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser,mints.block_timestamp, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,'held mints' as type,floor_price.label, floor_price.floor_price, named.bought_for, 
(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------




tx_table as (select *
from mint_holder
union all
select*
from secondary_holds
union all
select *
from resell)
select purchaser,label,sum(profit) as reselling_money_made from tx_table
group by purchaser,label
")

file.location <- "rishi.RData"
save(rishi, file = file.location)

profit <- QuerySnowflake("with mints as (
  SELECT distinct mint, 
  mint_price,
  purchaser
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (Select seller, sum(profit) as reselling_money_made
from profitt
  group by seller
  order by reselling_money_made desc),
  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser ,sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),

//adujst floor price calculation
labeled as(select labels.label, recent.purchaser, recent.bought_for
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select labeled.purchaser, sum(floor_price.floor_price - labeled.bought_for) as secondary_bought_holds
from labeled
inner join floor_price on  labeled.label = floor_price.label
group by labeled.purchaser
order by secondary_bought_holds desc),



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select named.purchaser, sum(floor_price.floor_price - named.bought_for) as net_worth_of_holds
from named
inner join floor_price on  named.label = floor_price.label
group by named.purchaser
order by net_worth_of_holds desc),

--resell, secondary_holds, mint_holder------------------


people_list as (SELECT people, Count(*) as Count FROM
(
  SELECT seller as people FROM resell
  UNION ALL
  SELECT purchaser as people FROM secondary_holds
  UNION ALL
  SELECT purchaser as people FROM mint_holder
) 
Group by people),

adding_mints as (
  select people_list.people, 
  case when mint_holder.net_worth_of_holds is null then 0 else mint_holder.net_worth_of_holds end as mints_value
  from people_list
   full outer join mint_holder on people_list.people = mint_holder.purchaser
   ),
   
adding_secondary as (
  select adding_mints.people, 
  
  case when secondary_holds.secondary_bought_holds  is null then 0 else secondary_holds.secondary_bought_holds  end as secondary_bought_holds,
  adding_mints.mints_value
  from adding_mints
   full outer join secondary_holds on adding_mints.people = secondary_holds.purchaser
 ),
 
 
 
adding_resell as (
    select adding_secondary.people, 
  adding_secondary.mints_value,
  adding_secondary.secondary_bought_holds,
  
  case when resell.reselling_money_made is null then 0 else   resell.reselling_money_made  end as resold_profits
  from adding_secondary
   full outer join resell on adding_secondary.people = resell.seller
)
----------this is the table off all everything----getting the three ways and then the total of all the profits
select adding_resell.people, 
adding_resell.mints_value + 
adding_resell.secondary_bought_holds as holds, 
adding_resell.resold_profits as resold,
adding_resell.mints_value + adding_resell.secondary_bought_holds + adding_resell.resold_profits as total
from adding_resell
where adding_resell.people != 'NULL'
order by total desc"
                         
)
file.location <- "profit.RData"
save(profit, file = file.location)


table <- QuerySnowflake("with mints as (
  SELECT distinct mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,'resell' as type, case when labels.label is null then 'Unlabeled' else labels.label end as label,
 profitt.bought_price,profitt.sold_for,
   profitt.profit
from profitt
full outer join solana.core.dim_labels labels on profitt.mint = labels.address),
//this is getting every single resold nft from the sales table, and then seeing what it was sold for and
//what the person bought it as and calcing the profit, when theres no previous sale it uses mint price

  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
full outer join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price, 
  labeled.bought_for, 
  floor_price.floor_price - labeled.bought_for as profit
from labeled
inner join floor_price on  labeled.label = floor_price.label),




-----------BREAK---------------------------------------


diamond_hands as (SELECT distinct mints.mint,mints.purchaser,mints.block_timestamp, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
full outer join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('month',block_timestamp) as date, 
named.purchaser,'held mints' as type,floor_price.label, floor_price.floor_price, named.bought_for, 
(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------

tx_table as (select *
from mint_holder
union all
select*
from secondary_holds
union all
select *
from resell),

omg as (select date,purchaser,sum(profit) as money
from tx_table
group by date,purchaser)


select date,purchaser,money,SUM(money) OVER ( partition by purchaser order BY date asc) AS RunningTotal
 from omg  
order by date asc 

"
)

file.location <- "table.RData"
save(table, file = file.location)


resold<- QuerySnowflake("with mints as (
  SELECT distinct mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, seller,sum(profit) as profit
from profitt
group by seller,date
          )

    
select *,sum(profit) OVER ( partition by seller order BY date asc) AS resold_p from resell 
  group by date,seller,profit
order by date asc")

file.location <- "resold.RData"
save(resold, file = file.location)



held_nfts <- QuerySnowflake("with recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
full outer join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,
  sum(floor_price.floor_price - labeled.bought_for) as profit
from labeled
inner join floor_price on  labeled.label = floor_price.label
group by purchaser,date)

  
select *,sum(profit) OVER ( partition by purchaser order BY date asc) AS held_nfts_p from secondary_holds
  group by date,purchaser,profit
order by date asc")
file.location <- "held_nfts.RData"
save(held_nfts, file = file.location)

held_mints <- QuerySnowflake("with diamond_hands as (SELECT distinct mints.mint,mints.purchaser,mints.block_timestamp, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),  
  named as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
full outer join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('day',block_timestamp) as date, 
named.purchaser, sum(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label
group by date,purchaser)

select *,sum(profit) OVER ( partition by purchaser order BY date asc) AS held_mints_p from mint_holder
  group by date,purchaser,profit

order by date asc")

file.location <- "held_mints.RData"
save(held_mints, file = file.location)



transactions <- QuerySnowflake("with mints as (
  SELECT mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,
   profitt.profit
from profitt
inner join solana.core.dim_labels labels on profitt.mint = labels.address),

  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select labels.label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


held_nfts as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,
  floor_price.floor_price - labeled.bought_for as net_worth_of_holds
from labeled
inner join floor_price on  labeled.label = floor_price.label)

,



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser,mints.block_timestamp, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



held_mints as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------

calendar as (select days,person,count(*) as counted
from (
  select resell.date as days,resell.seller as person from resell
  union ALL
  select held_nfts.date as days, held_nfts.purchaser as person  from held_nfts
  union all 
  select held_mints.date as days, held_mints.purchaser from held_mints
)
group by days,person)


select person, cast(min(days) As Date) as first_day,  cast(max(days) As Date) as most_recent, max(counted) as highest_txs_in_a_day from calendar
group by person")
file.location <- "transactions.RData"
save(transactions, file = file.location)

calendar <- QuerySnowflake("with mints as (
  SELECT mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,
   profitt.profit
from profitt
inner join solana.core.dim_labels labels on profitt.mint = labels.address),

  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select labels.label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


held_nfts as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,
  floor_price.floor_price - labeled.bought_for as net_worth_of_holds
from labeled
inner join floor_price on  labeled.label = floor_price.label)

,



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser,mints.block_timestamp, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



held_mints as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------

calendar as (select days,person,count(*) as counted
from (
  select resell.date as days,resell.seller as person from resell
  union ALL
  select held_nfts.date as days, held_nfts.purchaser as person  from held_nfts
  union all 
  select held_mints.date as days, held_mints.purchaser from held_mints
)
group by days,person)


select person, days, sum(counted) as txs from calendar
group by person,days")
file.location <- "calendar.RData"
save(calendar, file = file.location)

tx_table <- QuerySnowflake("with mints as (
  SELECT mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,'resell' as type, labels.label,
 profitt.bought_price,profitt.sold_for,
   profitt.profit
from profitt
inner join solana.core.dim_labels labels on profitt.mint = labels.address),

  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select labels.label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price, 
  labeled.bought_for, 
  floor_price.floor_price - labeled.bought_for as net_worth_of_holds
from labeled
inner join floor_price on  labeled.label = floor_price.label)

,



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser,mints.block_timestamp, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,'held mints' as type,floor_price.label, floor_price.floor_price, named.bought_for, 
(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label)

--resell, secondary_holds, mint_holder------------------



select *
from mint_holder
union all
select*
from secondary_holds
union all
select *
from resell")
file.location <- "tx_table.RData"
save(tx_table, file = file.location)

market <- QuerySnowflake("with mints as (
  SELECT mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,marketplace,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, rishi.marketplace,
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.bought_for,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,'resell' as type, labels.label, profitt.profit,profitt.marketplace
from profitt
inner join solana.core.dim_labels labels on profitt.mint = labels.address),

  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,marketplace,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,marketplace,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select labels.label, recent.purchaser, recent.bought_for, recent.block_timestamp,recent.marketplace
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price - labeled.bought_for as net_worth_of_holds,
   labeled.marketplace
from labeled
inner join floor_price on  labeled.label = floor_price.label)

,



-----------BREAK---------------------------------------


--resell, secondary_holds, mint_holder------------------




tx_table as (
select*
from secondary_holds
union all
select *
from resell)


select distinct marketplace, purchaser, count(*) as number
from tx_table
group by marketplace,purchaser")
file.location <- "market.RData"
save(market, file = file.location)


collections <- QuerySnowflake("with 
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select labels.label, recent.purchaser, recent.bought_for, recent.block_timestamp,recent.mint
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price, 
  labeled.bought_for, 
  floor_price.floor_price - labeled.bought_for as net_worth_of_holds,
                    labeled.mint
from labeled
inner join floor_price on  labeled.label = floor_price.label)

,



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser,mints.block_timestamp, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp,diamond_hands.mint
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,'held mints' as type,floor_price.label, floor_price.floor_price, named.bought_for, 
(floor_price.floor_price - named.bought_for) as profit, named.mint
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------




tx_table as (select *
from mint_holder
union all
select*
from secondary_holds)


select case when solana.core.dim_nft_metadata.image_url is NULL then 'https://arweave.net/-8OK7wgcJKM37Y2XjuR0a8PzbEdkTVhLl4MqBGocL7E?ext=png' else  solana.core.dim_nft_metadata.image_url end as image ,
tx_table.date,
tx_table.purchaser,
tx_table.type,
tx_table.label,
tx_table.floor_price,
tx_table.bought_for,
tx_table.profit
from tx_table
full join solana.core.dim_nft_metadata  on tx_table.mint = solana.core.dim_nft_metadata.mint
order by profit desc")

file.location <- "collections.RData"
save(collections, file = file.location)



whales <- QuerySnowflake("with mints as (
  SELECT mint, 
  mint_price,
  purchaser
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (Select seller, sum(profit) as reselling_money_made
from profitt
  group by seller
  order by reselling_money_made desc),
  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser ,sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),

//adujst floor price calculation
labeled as(select labels.label, recent.purchaser, recent.bought_for
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select labeled.purchaser, sum(floor_price.floor_price - labeled.bought_for) as secondary_bought_holds
from labeled
inner join floor_price on  labeled.label = floor_price.label
group by labeled.purchaser
order by secondary_bought_holds desc),



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select named.purchaser, sum(floor_price.floor_price - named.bought_for) as net_worth_of_holds
from named
inner join floor_price on  named.label = floor_price.label
group by named.purchaser
order by net_worth_of_holds desc),

--resell, secondary_holds, mint_holder------------------


people_list as (SELECT people, Count(*) as Count FROM
(
  SELECT seller as people FROM resell
  UNION ALL
  SELECT purchaser as people FROM secondary_holds
  UNION ALL
  SELECT purchaser as people FROM mint_holder
) 
Group by people),

adding_mints as (
  select people_list.people, 
  case when mint_holder.net_worth_of_holds is null then 0 else mint_holder.net_worth_of_holds end as mints_value
  from people_list
   full outer join mint_holder on people_list.people = mint_holder.purchaser
   ),
   
adding_secondary as (
  select adding_mints.people, 
  
  case when secondary_holds.secondary_bought_holds  is null then 0 else secondary_holds.secondary_bought_holds  end as secondary_bought_holds,
  adding_mints.mints_value
  from adding_mints
   full outer join secondary_holds on adding_mints.people = secondary_holds.purchaser
 ),
 
 
 
adding_resell as (
    select adding_secondary.people, 
  adding_secondary.mints_value,
  adding_secondary.secondary_bought_holds,
  
  case when resell.reselling_money_made is null then 0 else   resell.reselling_money_made  end as resold_profits
  from adding_secondary
   full outer join resell on adding_secondary.people = resell.seller
)
----------this is the table off all everything----getting the three ways and then the total of all the profits
select adding_resell.people, 
adding_resell.mints_value,
adding_resell.secondary_bought_holds, 
adding_resell.resold_profits,
adding_resell.mints_value + adding_resell.secondary_bought_holds + adding_resell.resold_profits as total
from adding_resell
where adding_resell.people != 'NULL'
and secondary_bought_holds != 0
and resold_profits != 0
and mints_value != 0
order by total desc")

file.location <- "whales.RData"
save(whales, file = file.location)



top_collections <- QuerySnowflake("with mints as (
  SELECT mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,marketplace
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,'resell' as type, labels.label,
 profitt.bought_price,profitt.sold_for,
   profitt.profit as reselling_money_made
from profitt
inner join solana.core.dim_labels labels on profitt.mint = labels.address),

  
  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select labels.label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
inner join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price, 
  labeled.bought_for, 
  floor_price.floor_price - labeled.bought_for as net_worth_of_holds
from labeled
inner join floor_price on  labeled.label = floor_price.label)

,



-----------BREAK---------------------------------------


diamond_hands as (SELECT mints.purchaser,mints.block_timestamp, mints.mint, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select labels.label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
inner join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,'held mints' as type,floor_price.label, floor_price.floor_price, named.bought_for, 
(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------




tx_table as (select *
from mint_holder
union all
select*
from secondary_holds
union all
select *
from resell)



select label,purchaser, count(*) as volume
from tx_table 
where date > current_date - 90
group by label,purchaser
order by volume desc")

file.location <- "top_collections.RData"
save(top_collections, file = file.location)





whale_transactions <- QuerySnowflake("with mints as (
  SELECT distinct mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,'resell' as type, case when labels.label is null then 'Unlabeled' else labels.label end as label,
 profitt.bought_price,profitt.sold_for,
   profitt.profit
from profitt
full outer join solana.core.dim_labels labels on profitt.mint = labels.address),
//this is getting every single resold nft from the sales table, and then seeing what it was sold for and
//what the person bought it as and calcing the profit, when theres no previous sale it uses mint price

  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
full outer join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price, 
  labeled.bought_for, 
  floor_price.floor_price - labeled.bought_for as profit
from labeled
inner join floor_price on  labeled.label = floor_price.label),




-----------BREAK---------------------------------------


diamond_hands as (SELECT distinct mints.mint,mints.purchaser,mints.block_timestamp, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
full outer join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,'held mints' as type,floor_price.label, floor_price.floor_price, named.bought_for, 
(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------

tx_table as (select *
from mint_holder
union all
select*
from secondary_holds
union all
select *
from resell),
people_list as (SELECT people, Count(*) as Count FROM
(
  SELECT seller as people FROM resell
  UNION ALL
  SELECT purchaser as people FROM secondary_holds
  UNION ALL
  SELECT purchaser as people FROM mint_holder
) 
Group by people),

adding_mints as (
  select people_list.people,
  case when sum(mint_holder.profit) is null then 0 else sum(mint_holder.profit) end as mints_value
  from people_list
   full outer join mint_holder on people_list.people = mint_holder.purchaser
  group by people_list.people,mint_holder.purchaser
   ),
adding_secondary as (
  select adding_mints.people, 
  case when sum(secondary_holds.profit)  is null then 0 else sum(secondary_holds.profit) end as secondary_bought_holds,
  adding_mints.mints_value
  from adding_mints
  full outer join secondary_holds on adding_mints.people = secondary_holds.purchaser
  group by secondary_holds.purchaser,adding_mints.mints_value,adding_mints.people
 ),
 
 
 
adding_resell as (
    select adding_secondary.people, 
  adding_secondary.mints_value,
  adding_secondary.secondary_bought_holds,
  case when sum(resell.profit) is null then 0 else   sum(resell.profit)  end as resold_profits
  from adding_secondary
   full outer join resell on adding_secondary.people = resell.seller
  group by adding_secondary.secondary_bought_holds,adding_secondary.mints_value,adding_secondary.people, resell.seller
),
whale_list as (
select adding_resell.people, 
adding_resell.mints_value,
adding_resell.secondary_bought_holds, 
adding_resell.resold_profits,
adding_resell.mints_value + adding_resell.secondary_bought_holds + adding_resell.resold_profits as total
from adding_resell
where adding_resell.people != 'NULL'
and secondary_bought_holds != 0
and resold_profits != 0
and mints_value != 0
order by total desc
limit 100)
select label, count(*) as volume, avg(profit) as profit_avg
from tx_table
inner join whale_list on tx_table.purchaser = whale_list.people
group by label
order by volume desc
limit 10")
file.location <- "whale_transactions.RData"
save(whale_transactions, file = file.location)



whales_collections <- QuerySnowflake("with mints as (
  SELECT distinct mint, 
  mint_price,
  purchaser 
  from solana.core.fact_nft_mints
),
rishi as (select block_timestamp,
  purchaser, 
  seller,
  mint, 
  sales_amount as sold_for, 
  LAG(sales_amount, 1) OVER ( partition by mint ORDER BY block_timestamp) as bought_for
from solana.core.fact_nft_sales),

profitt as (
  select rishi.block_timestamp, 
  rishi.purchaser, 
  rishi.seller,
  rishi.mint, 
  mints.mint_price,
  mints.purchaser as minter,
  rishi.sold_for, 
  case when mints.mint_price is null then 0   
  when rishi.bought_for IS NULL then mints.mint_price
  else rishi.bought_for end as bought_price, 
  sold_for - bought_price as profit
  from rishi
  inner join mints on rishi.mint = mints.mint
),

resell as (select date_trunc('day',block_timestamp) as date, profitt.seller,'resell' as type, case when labels.label is null then 'Unlabeled' else labels.label end as label,
 profitt.bought_price,profitt.sold_for,
   profitt.profit
from profitt
full outer join solana.core.dim_labels labels on profitt.mint = labels.address),
//this is getting every single resold nft from the sales table, and then seeing what it was sold for and
//what the person bought it as and calcing the profit, when theres no previous sale it uses mint price

  
  
  -----------BREAK------------
  
recent as (select distinct mint,purchaser, block_timestamp, sales_amount as bought_for
From (SELECT RANK() OVER (PARTITION BY mint order by block_timestamp) 
      as RN,mint,block_timestamp,purchaser, sales_amount //as date 
      from solana.core.fact_nft_sales) as ST
Where ST.RN = 1),


labeled as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, recent.purchaser, recent.bought_for, recent.block_timestamp
from recent
full outer join solana.core.dim_labels labels on recent.mint = labels.address),

floor_table as (Select 
  labels.label, 
  sales.sales_amount,
  date_trunc('day',sales.block_timestamp) as date ,
  PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY sales_amount) OVER (PARTITION BY label) AS Median_UnitPrice
from solana.core.fact_nft_sales sales
join solana.core.dim_labels labels on sales.mint = labels.address
where date >= current_date - 10),


floor_price as (Select floor_table.label, avg(floor_table.Median_UnitPrice) as floor_price
from floor_table
group by label
order by floor_price desc),


secondary_holds as (select date_trunc('day',block_timestamp) as date,labeled.purchaser,'held nfts' as type,floor_price.label, 
  floor_price.floor_price, 
  labeled.bought_for, 
  floor_price.floor_price - labeled.bought_for as profit
from labeled
inner join floor_price on  labeled.label = floor_price.label),




-----------BREAK---------------------------------------


diamond_hands as (SELECT distinct mints.mint,mints.purchaser,mints.block_timestamp, mints.mint_price as bought_for
FROM solana.core.fact_nft_mints AS mints
LEFT OUTER JOIN solana.core.fact_nft_sales AS sales
ON mints.mint = sales.mint
WHERE sales.mint IS NULL
and mints.mint_currency = 'So11111111111111111111111111111111111111111'),
--this is getting not traded and minted nfts

  
  named as(select case when labels.label is null then 'Unlabeled' else labels.label end as label, diamond_hands.purchaser, diamond_hands.bought_for,diamond_hands.block_timestamp
from diamond_hands
full outer join solana.core.dim_labels labels on diamond_hands.mint = labels.address),
--this is getting labels on them



mint_holder as (select date_trunc('day',block_timestamp) as date, 
named.purchaser,'held mints' as type,floor_price.label, floor_price.floor_price, named.bought_for, 
(floor_price.floor_price - named.bought_for) as profit
from named
inner join floor_price on  named.label = floor_price.label),

--resell, secondary_holds, mint_holder------------------

tx_table as (select *
from mint_holder
union all
select*
from secondary_holds
union all
select *
from resell),
people_list as (SELECT people, Count(*) as Count FROM
(
  SELECT seller as people FROM resell
  UNION ALL
  SELECT purchaser as people FROM secondary_holds
  UNION ALL
  SELECT purchaser as people FROM mint_holder
) 
Group by people),

adding_mints as (
  select people_list.people,
  case when sum(mint_holder.profit) is null then 0 else sum(mint_holder.profit) end as mints_value
  from people_list
   full outer join mint_holder on people_list.people = mint_holder.purchaser
  group by people_list.people,mint_holder.purchaser
   ),
adding_secondary as (
  select adding_mints.people, 
  case when sum(secondary_holds.profit)  is null then 0 else sum(secondary_holds.profit) end as secondary_bought_holds,
  adding_mints.mints_value
  from adding_mints
  full outer join secondary_holds on adding_mints.people = secondary_holds.purchaser
  group by secondary_holds.purchaser,adding_mints.mints_value,adding_mints.people
 ),
 
 
 
adding_resell as (
    select adding_secondary.people, 
  adding_secondary.mints_value,
  adding_secondary.secondary_bought_holds,
  case when sum(resell.profit) is null then 0 else   sum(resell.profit)  end as resold_profits
  from adding_secondary
   full outer join resell on adding_secondary.people = resell.seller
  group by adding_secondary.secondary_bought_holds,adding_secondary.mints_value,adding_secondary.people, resell.seller
),
whale_list as (
select adding_resell.people, 
adding_resell.mints_value,
adding_resell.secondary_bought_holds, 
adding_resell.resold_profits,
adding_resell.mints_value + adding_resell.secondary_bought_holds + adding_resell.resold_profits as total
from adding_resell
where adding_resell.people != 'NULL'
and secondary_bought_holds != 0
and resold_profits != 0
and mints_value != 0
order by total desc
limit 100)
select label, count(distinct purchaser) as percent, count(*)
from tx_table
inner join whale_list on tx_table.purchaser = whale_list.people
group by label
order by percent desc
limit 10")

file.location <- "whales_collections.RData"
save(whales_collections, file = file.location)

















