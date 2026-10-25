# Amazon A/B Testing: Checkout Conversion Experiment

## Project Overview
An end-to-end A/B testing portfolio project evaluating whether a simplified e-commerce checkout experience improves conversion rates and revenue per session.

The project combines statistical analysis, commercial scenario modelling and Power BI visualisation to translate experimental results into a business recommendation.

**Note:** This is a synthetic, Amazon-inspired case study. It does not use actual Amazon customer data or represent Amazon's real performance.
## Dashboard Preview

### 1. Experiment Overview
![Experiment Overview](screenshots/experiment-overview.png)

### 2. Experiment Outcomes
![Experiment Outcomes](screenshots/experiment-outcomes.png)

### 3. Commercial Impact
![Commercial Impact](screenshots/commercial-impact.png)

### 4. Decision & Limitations
![Decision and Limitations](screenshots/decision-limitations.png)

## Business Question
Does a simplified checkout experience improve conversion compared with the existing checkout?

## Experiment Design
- **Total sample:** 12,000 sessions
- **Control group:** 6,000 sessions
- **Treatment group:** 6,000 sessions
- **Simulated period:** 30 days
- **Primary metric:** Conversion rate
- **Secondary metric:** Revenue per session
- **Significance threshold:** 5%

## Key Findings
- **Control conversion rate:** 10.08%
- **Treatment conversion rate:** 11.15%
- **Absolute conversion lift:** +1.07 percentage points
- **Relative conversion lift:** +10.58%
- **Conversion test p-value:** 0.0579
- **Revenue per session:** £12.08 control vs £13.33 treatment
- **Revenue per session test p-value:** 0.1068

Neither difference was statistically significant at the 5% level. The observed uplifts are not sufficient to confirm a reliable improvement.

## Commercial Analysis
The project models potential monthly gross revenue under different conversion-rate scenarios, using an assumed 100,000 monthly sessions and an average order value of approximately £119.71.

These scenarios are illustrative, not forecasts or guaranteed returns. They represent gross revenue rather than profit and exclude variable operating costs.

## Recommendation
Increase the sample beyond 12,000 sessions and repeat the experiment using a predefined sample-size calculation and decision criteria. Assess statistical significance, commercial value and customer-experience metrics before deciding whether to roll out the change.

## Tools
- Power BI — dashboard development and visualisation
- Python — statistical analysis
- SQL — data querying and analysis

## Limitations
- The dataset is synthetic and cannot establish actual customer behaviour.
- The experiment did not demonstrate statistically significant differences.
- Commercial scenarios depend on assumptions about traffic, order value and costs.

## Project Status
Portfolio case study completed; further testing would be required before a real-world rollout decision.
