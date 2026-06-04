select
    status_primary,
    count(*) as claim_count,
    sum(outstanding_primary) as total_outstanding,
    avg(outstanding_primary) as avg_outstanding
from {{ ref('stg_claims') }}
group by 1
