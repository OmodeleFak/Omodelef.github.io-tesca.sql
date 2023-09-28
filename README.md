# business_analysis
Solution provided to this project include
1. Architectural Design
2. Bubble Chart
3. Stakeholders' Matrix
4. Bus Matrix
5. Source-to-Target Mapping
6. Enterprice Data Warehouse (with the physical model)
7. ETL Development Script
   
❑ Background:
▪ Tesca Grocery chain consists of 830 stores in 74 states
▪ Distribute products received from certified vendors to stores
▪ Stores 40 products in 7 departments, such as frozen foods and diary
▪ Bar codes are scanned directly into the cash registers’ POS System by Sales 
person
▪ Sales Products are promoted via coupons, temporary price reductions, ads, and in 
store promotions
▪ Purchasing department received products from vendor
▪ Salespersons overtime hours are captured in Excel by Sales Manager
▪ Human Resources Department already provided download CSV files of uncleaned 
employee misconduct and absence data with many duplications, and anomalous
absence and misconduct data
Below are the de-duplication business rules:
• The first entry of the absence data for a day is the right record to be 
retained
• The last entry of the employee misconduct data for a day is the right 
record to be retained
▪ Backup of the Tesca Grocery Chain Transaction Processing System has been 
provided to you
▪ Database Administrator has granted full administrative privileges on both 
Analysis and Relational Database Instances
❑ Analytic Requirements:
1. Need to know what is selling in the stores each day to evaluate product movement, as well 
as to see how sales are impacted by promotions
2. Need to understand the mix of products in a customer’s market basket
3. Changes to Point of Sales Device on each channel are recorded to know the frequency of 
channel POS device replacement
4. Need to understand the most ordered products from each Vendor in each store
5. The management decided to track changes to vendor information to determine the impact 
on the delivery services
6. Sales Manager is interested to know the effects of product rebranding on Sales
7. Human Resources Management needs to know the effects of changes to marital status on 
salesperson’s overtime hours
8. Needs to perform sales analysis on overall product brand sales and rebrand product sales
9. Purchasing Manager needs to know the efficient vendors based on differential days between
order date and delivery date 
10. Sales Manager needs to know what are the most demanding products for each time period 
of the day
11. Employee misconducts analysis is requested by the management as part of the ongoing 
strategy to improved work ethics and customer satisfaction
12. Need to understand Employee Absence trends for performance appraisal and to proactively 
plan for new employee recruitment to meet the service expectation of Tesca customers
Deliverables:
▪ You are required to build an Enterprise Data ware housing that addresses the 
analytic requirements
