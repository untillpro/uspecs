# How: uhow command self-answers uncertainties

## Functional design

### Number of uncertainties to identify

Three uncertainties per run (confidence: high).

Choice architecture research shows that presenting 3-5 options balances comprehensiveness with cognitive load. Three uncertainties provide enough depth without overwhelming while keeping responses focused and actionable.

See: [The Paradox of Choice - The Decision Lab](https://thedecisionlab.com/reference-guide/economics/the-paradox-of-choice)

- Five uncertainties per run (confidence: medium)
  - More thorough but risks cognitive overload
- Single uncertainty per run (confidence: low)
  - Too incremental, requires many iterations

### Number of alternatives per uncertainty

Two alternatives after the primary answer (confidence: high).

Providing one primary answer plus two alternatives gives Engineers enough options to override AI judgment while keeping the output scannable. Research on simultaneous option presentation shows this aids better decision-making.

See: [Choosing one at a time? Presenting options simultaneously helps people make better decisions](https://www.sciencedirect.com/science/article/abs/pii/S0749597816302060)

- Single alternative (confidence: medium)
  - Simpler but may miss important options
- Three or more alternatives (confidence: low)
  - Choice overload, diminishes practical value

### Confidence level notation

Use categorical labels: high, medium, low (confidence: high).

Categorical labels are more interpretable than percentages for qualitative assessments. The RICE scoring model and similar frameworks use similar categorical confidence levels for subjective estimates. This aligns with existing how.md template format.

See: [RICE Scoring Model - ProductPlan](https://www.productplan.com/glossary/rice-scoring-model/)

- Percentage-based (80%, 50%, 20%) (confidence: medium)
  - See: [8 Prioritization Frameworks - Savio](https://www.savio.io/product-roadmap/prioritization-frameworks/)
  - More precise but false precision for subjective assessments
- No confidence indicators (confidence: low)
  - Loses valuable signal about certainty

## References

- [The Paradox of Choice - The Decision Lab](https://thedecisionlab.com/reference-guide/economics/the-paradox-of-choice): Choice architecture and cognitive load research
- [Choosing one at a time? Presenting options simultaneously](https://www.sciencedirect.com/science/article/abs/pii/S0749597816302060): Research on presenting multiple options for decision-making
- [RICE Scoring Model - ProductPlan](https://www.productplan.com/glossary/rice-scoring-model/): Confidence level categorization patterns
- [8 Prioritization Frameworks - Savio](https://www.savio.io/product-roadmap/prioritization-frameworks/): Alternative confidence notation approaches
