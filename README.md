# Telecom Churn Analysis

**Summary:** This is an end-to-end data analysis portfolio project based on a telecom customer churn [dataset](https://mavenanalytics.io/data-playground/telecom-customer-churn).

## Business Problem

Telecom company X suspects it is experiencing significant customer churn but has been unable to pinpoint the underlying causes. The goal of this project is to analyze the available data, identify the root causes of churn, and develop a data-driven decision-making framework to address the problem.

## Workflow

1. Building a PostgreSQL database from scratch using a transactional schema (vertical partitioning) and Third Normal Form (3NF)
2. Data preprocessing for analysis and machine learning
3. In-depth exploratory, descriptive, and diagnostic analysis using Python and libraries: Pandas, Seaborn, Matplotlib, and Jupyter
4. Training and evaluating a machine learning model to predict the churn probability for each customer (predictive analysis)
5. Performing expected value analysis to prioritize high-risk customers (prescriptive analysis) using model outputs and existing data

## Findings

As suspected by company X, a notable churn problem exists. **26.56% of all customers churned** in the observed period (no churn date is available in the dataset, but the scenario assumes a recent window).

The drivers of churn can be grouped into the following categories:

### Early Experience & Offers

Over 53% of new customers churn within seven months, accounting for 20% of total churn. This points to early-stage friction or a failure to communicate value effectively. The majority of customers also prefer month-to-month contracts, which increases their exposure to churn.

![Churns by Tenure](/data/graphs/by_tenure.png)

The most common churn reasons are *Competitor had better devices* and *Competitor made better offer*, suggesting that competitors bundle devices with their plans — something company X's current offers do not appear to match.

![Churns by Reason](/data/graphs/by_reason.png)

Most churn is associated with Offer E or no offer at all (standard pricing). These are also the only offers available to customers in roughly their first six months, based on the data.

![Churn by Offer](/data/graphs/by_offers.png)

![Churns by Offer (First Six Months)](/data/graphs/by_offers_in_six.png)

### Infrastructure

Download speed-related churn is concentrated among fiber optic users, suggesting infrastructural deficiencies in this service tier.

![Churns by Internet Type](/data/graphs/by_internet_type.png)

### Location

San Diego is company X's second-largest market by customer count, yet its churn rate exceeds 65% — the highest of any city — driven primarily by superior competitor offers.

Despite 68% fiber optic adoption in the city, speed-related complaints such as *Competitor offered higher download speeds* and *Lack of affordable download/upload speed* do not appear among the top five churn reasons. This suggests that pricing or network stability, rather than raw speed, is the primary competitive disadvantage in the region.

![Churn Rate by Location](/data/graphs/by_location.png)

### Other

- Customer communication issues account for 20.55% of churn, though the available data on this topic is limited.

- Price-related factors drive nearly 26% of all churn, though a full pricing analysis is not feasible without competitor data.

![Churns by Category](/data/graphs/by_category.png)

> **Note:** Figures in the churn categories plot may differ slightly from calculated values. See *02-dda.ipynb* for details.

## Recommendations

Company X should focus on the following:

- Researching competitor offers and revising early-stage pricing and promotions accordingly
- Engaging new customers more proactively and offering greater flexibility in plan selection from the start
- Investigating the root cause of churn in San Diego specifically
- Evaluating and improving fiber optic infrastructure where feasible
- Deploying the machine learning model in *03-pda-ml.ipynb* for ongoing churn prediction, or developing a more advanced model using internal resources
- Using the expected value analysis in *04-presc.ipynb* to prioritize at-risk customers and maximize retention ROI

## Machine Learning Model

A Random Forest classifier was selected for its robustness to outliers and skewed distributions common characteristics of this dataset. This approach enabled strong performance without aggressive feature scaling or transformation, preserving the integrity of the original data.

**ROC-AUC Score: 0.894**

| Metrics       | Not Churned | Churned | Accuracy |
| ------------- | ----------- | ------- | -------- |
| **Precision** | 0.90        | 0.66    | 0.83     |
| **Recall**    | 0.86        | 0.73    | 0.83     |
| **F1-Score**  | 0.88        | 0.69    | 0.83     |

![Confusion Matrix](/data/results/cm.png)

While the ROC-AUC score reflects solid overall discriminative ability, precision and F1 scores for the churned class remain moderate despite extensive hyperparameter tuning and feature selection. This suggests the model has likely reached its performance ceiling with Random Forest on this dataset; architectures such as XGBoost or LightGBM may yield further improvements.

That said, the model remains highly actionable: recall improved from 0.72 to 0.78 across iterations, reducing missed churners from 102 to 82. The classification threshold can also be adjusted to better align precision and recall with specific business goals and budget constraints.

## Limitations

### Dataset Limitations

- **No churn date:** The dataset does not include a timestamp for when customers churned, making it impossible to conduct time-series analysis or measure churn velocity over time.
- **No competitor data:** Price and offer comparisons are inferred entirely from customer-reported churn reasons. Without actual competitor pricing or plan data, it is not possible to quantify the competitive gap or model price elasticity.
- **Limited communication data:** Customer communication is one of the leading churn categories, yet the dataset provides little detail on the nature, frequency, or outcome of these interactions.

### Hardware Limitations

- Model training and hyperparameter tuning were performed on consumer-grade hardware, which constrained the feasibility of more computationally intensive approaches such as extensive grid search, ensemble stacking, or neural network architectures.

## Tech Stack

| Layer | Tools |
|---|---|
| **Database** | PostgreSQL |
| **Data Analysis** | Python, Pandas, Seaborn, Matplotlib, Jupyter Notebook |
| **Machine Learning** | Scikit-learn (Random Forest) |

## How to Run

### Prerequisites

- Python 3.8+
- PostgreSQL installed and running locally
- Jupyter Notebook

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/wviryan/telechurn.git

cd telechurn
```

2. **Create and activate a virtual environment**

```bash
python -m venv venv

source venv/bin/activate        # macOS/Linux

venv\Scripts\activate           # Windows
```

3. **Install dependencies**

```bash
pip install -r requirements.txt
```

4. **Create a .env file in project directory (not mandatory)**

```
USER=postgres
PASSWORD=123456
HOST=localhost
PORT=5432
DATABASE=churn_analysis
```

5. **Set up the database (not mandatory)**

- Create a new PostgreSQL database and run the schema and seed scripts found in the `/sql` directory.
- **Note:** You can skip this part by directly connecting `01-database.ipynb` source to raw data in the repo.

5. **Launch Jupyter Notebook**

```bash
jupyter notebook
```

6. **Run the notebooks in order**
- `01-database.ipynb` — Database setup and data loading
- `02-dda.ipynb` — Exploratory and diagnostic analysis
- `03-pda-ml.ipynb` — Machine learning model
- `04-presc.ipynb` — Expected value and prescriptive analysis