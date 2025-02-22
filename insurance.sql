-- TODO:1. 退保率
-- 从保单表中查询数据，计算每个区域的退保率
SELECT
    -- 选择区域字段，用于区分不同地区的退保情况
    region,
    -- 计算退保率：退保金总和除以（寿险责任准备金与长期健康险责任准备金总和 + 保费总和），再乘以 100 转换为百分比
    SUM(surrender_value) / (
        SUM(life_insurance_reserve + long_term_health_insurance_reserve) + SUM(premium)
    ) * 100 AS surrender_rate
FROM
    -- 从保单表中获取数据
    policy
WHERE
    -- 仅筛选出保单类型为长期险的数据，因为退保率通常针对长期险进行计算
    policy_type = '长期险'
GROUP BY
    -- 按区域分组，以便分别计算每个区域的退保率
    region;

-- TODO:2. 未决赔款准备金与赔款支出比
-- 从赔付表中查询数据，计算每个区域的未决赔款准备金与赔款支出比
SELECT
    -- 选择区域字段，用于区分不同地区的该比例情况
    region,
    -- 计算未决赔款准备金与赔款支出比：已发生已报告未决赔款准备金总和除以已付赔款总和，再乘以 100 转换为百分比
    SUM(reported_unsettled_claim_reserve) / SUM(paid_claim_amount) * 100 AS reserve_to_claim_ratio
FROM
    -- 从赔付表中获取数据
    claim_payment
GROUP BY
    -- 按区域分组，以便分别计算每个区域的该比例
    region;

-- TODO: 3. 已付赔款赔付率（业务年度）
-- 从保单表和赔付表中联合查询数据，计算每个区域和业务年度的已付赔款赔付率
SELECT
    -- 选择区域字段，用于区分不同地区的赔付率情况
    region,
    -- 选择业务年度字段，用于区分不同年份的赔付率情况
    business_year,
    -- 计算已付赔款赔付率：已付赔款总和除以对应保单的保费总和，再乘以 100 转换为百分比
    SUM(paid_claim_amount) / SUM(p.premium) * 100 AS paid_claim_ratio
FROM
    -- 从保单表中获取数据，使用别名 p
    policy p
JOIN
    -- 从赔付表中获取数据，使用别名 cp，并通过保单编号进行关联
    claim_payment cp ON p.policy_id = cp.policy_id
GROUP BY
    -- 按区域和业务年度分组，以便分别计算每个区域和年份的赔付率
    region, business_year;

-- 4. 已报告赔款赔付率（业务年度
-- 从保单表和赔付表中联合查询数据，计算每个区域和业务年度的已报告赔款赔付率
SELECT
    -- 选择区域字段，用于区分不同地区的赔付率情况
    region,
    -- 选择业务年度字段，用于区分不同年份的赔付率情况
    business_year,
    -- 计算已报告赔款赔付率：（已决赔款总和 + 已发生已报告未决赔款准备金总和）除以对应保单的保费总和，再乘以 100 转换为百分比
    (SUM(settled_claim_amount) + SUM(reported_unsettled_claim_reserve)) / SUM(p.premium) * 100 AS reported_claim_ratio
FROM
    -- 从保单表中获取数据，使用别名 p
    policy p
JOIN
    -- 从赔付表中获取数据，使用别名 cp，并通过保单编号进行关联
    claim_payment cp ON p.policy_id = cp.policy_id
GROUP BY
    -- 按区域和业务年度分组，以便分别计算每个区域和年份的赔付率
    region, business_year;
