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

-- TODO:5. 业务年度赔付率
-- 从保单表和赔付表中联合查询数据，计算每个区域和业务年度的业务年度赔付率
SELECT
    -- 选择区域字段，用于区分不同地区的赔付率情况
    region,
    -- 选择业务年度字段，用于区分不同年份的赔付率情况
    business_year,
    -- 计算业务年度赔付率：（已决赔款总和 + 已发生已报告未决赔款准备金总和 + 已发生未报告未决赔款准备金总和）除以对应保单的保费总和，再乘以 100 转换为百分比
    (SUM(settled_claim_amount) + SUM(reported_unsettled_claim_reserve) + SUM(unreported_unsettled_claim_reserve)) / SUM(p.premium) * 100 AS business_year_claim_ratio
FROM
    -- 从保单表中获取数据，使用别名 p
    policy p
JOIN
    -- 从赔付表中获取数据，使用别名 cp，并通过保单编号进行关联
    claim_payment cp ON p.policy_id = cp.policy_id
GROUP BY
    -- 按区域和业务年度分组，以便分别计算每个区域和年份的赔付率
    region, business_year;
-- TODO:6. 综合资本成本率
-- 使用公共表表达式（CTE） liability_summary 计算每个区域的各类负债和所有者权益总和
WITH liability_summary AS (
    SELECT
        -- 选择区域字段，用于区分不同地区的情况
        o.region,
        -- 计算每个区域的保险负债总和
        SUM(l.insurance_liability_amount) AS total_insurance_liability,
        -- 计算每个区域的运营类负债总和
        SUM(l.operation_liability_amount) AS total_operation_liability,
        -- 计算每个区域的金融负债总和
        SUM(l.financial_liability_amount) AS total_financial_liability,
        -- 计算每个区域的所有者权益总和
        SUM(o.registered_capital) AS total_equity
    FROM
        -- 从机构表中获取数据，使用别名 o
        organization o
    JOIN
        -- 从负债表中获取数据，使用别名 l，并通过机构编号进行关联
        liability l ON o.organization_id = l.organization_id
    WHERE
        -- 仅筛选出负债日期为 2024-01-01 的数据
        l.liability_date = '2024-01-01'
    GROUP BY
        -- 按区域分组，以便分别计算每个区域的各类负债和所有者权益总和
        o.region
),
-- 使用公共表表达式（CTE） weighted_cost 计算每个区域各类资金来源的加权成本
weighted_cost AS (
    SELECT
        -- 选择区域字段，用于区分不同地区的情况
        ls.region,
        -- 计算保险负债的加权成本：保险负债占总资金（各类负债和所有者权益之和）的比例乘以保险负债成本率
        (ls.total_insurance_liability / (ls.total_insurance_liability + ls.total_operation_liability + ls.total_financial_liability + ls.total_equity)) * ccr.insurance_liability_rate AS insurance_liability_weighted_cost,
        -- 计算运营类负债的加权成本：运营类负债占总资金的比例乘以运营类负债成本率
        (ls.total_operation_liability / (ls.total_insurance_liability + ls.total_operation_liability + ls.total_financial_liability + ls.total_equity)) * ccr.operation_liability_rate AS operation_liability_weighted_cost,
        -- 计算金融负债的加权成本：金融负债占总资金的比例乘以金融负债成本率
        (ls.total_financial_liability / (ls.total_insurance_liability + ls.total_operation_liability + ls.total_financial_liability + ls.total_equity)) * ccr.financial_liability_rate AS financial_liability_weighted_cost,
        -- 计算所有者权益的加权成本：所有者权益占总资金的比例乘以所有者权益成本率
        (ls.total_equity / (ls.total_insurance_liability + ls.total_operation_liability + ls.total_financial_liability + ls.total_equity)) * ccr.equity_cost_rate AS equity_weighted_cost
    FROM
        -- 从 liability_summary 中获取数据，使用别名 ls
        liability_summary ls
    JOIN
        -- 从资本成本率表中获取数据，使用别名 ccr，并通过日期进行关联
        capital_cost_rate ccr ON ccr.date = '2024-01-01'
)
-- 从 weighted_cost 中查询数据，计算每个区域的综合资本成本率
SELECT
    -- 选择区域字段，用于区分不同地区的情况
    region,
    -- 计算综合资本成本率：各类资金来源的加权成本之和
    insurance_liability_weighted_cost + operation_liability_weighted_cost + financial_liability_weighted_cost + equity_weighted_cost AS comprehensive_capital_cost_rate
FROM
    -- 从 weighted_cost 中获取数据
    weighted_cost;