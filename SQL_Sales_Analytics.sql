create database pbi_project;
select *from categories;
select * from customers;
select * from employees;
select * from order_details;
select * from orders;
select * from products;
select * from shippers;
select * from suppliers;

-- 1.What is the average number of orders per customer? 
SELECT AVG(OrderCount) AS AvgOrdersPerCustomer
FROM (
    SELECT CustomerID, COUNT(OrderID) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
) AS CustomerOrderCounts;

-- Are there high-value repeat customers?
select o.CustomerID,
count(o.OrderID) as total_orders,
sum(od.UnitPrice * od.Quantity - od.Discount) as total_spent,
avg(od.UnitPrice * od.Quantity - od.Discount) as avg_order_value
from orders o
join order_details od on o.OrderID = od.OrderID
group by o.CustomerID
having count(o.OrderID) > 1 and sum(od.UnitPrice * od.Quantity - od.Discount) > 1000
order by total_spent desc
limit 10;


-- 2.How do customer order patterns vary by city or country?

SELECT 
    Country,city,
    COUNT(o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS TotalCustomers,
    ROUND(COUNT(o.OrderID) * 1.0 / COUNT(DISTINCT o.CustomerID), 2) AS AvgOrdersPerCustomer
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY Country,city
ORDER BY TotalOrders DESC;

-- 3. Can we cluster customers based on total spend, order count, and preferred categories?

WITH customer_summary AS (
    SELECT 
        o.CustomerID,
       round( SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)),2) AS Total_Spend,
        COUNT(DISTINCT o.OrderID) AS Order_Count
    FROM Orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
)
SELECT *,
       CASE 
           WHEN Total_Spend > 10000 AND Order_Count > 20 THEN 'High Value Frequent'
           WHEN Total_Spend BETWEEN 5000 AND 10000 AND Order_Count BETWEEN 10 AND 20 THEN 'Medium Value Moderate'
           ELSE 'Low Value Infrequent'
       END AS Customer_Segment
FROM customer_summary
ORDER BY Total_Spend DESC;

-- Which product categories or products contribute most to order revenue?

select c.CategoryName,p.ProductName,round(sum(o.TotalSales),2) as Total_Sales
from order_details o
join 
	products p on o.ProductID=p.ProductID
join categories c on p.CategoryID=c.CategoryID
group by CategoryName,ProductName
order by Total_Sales desc;

-- 5 .Are there any correlations between orders and customer location or product category?

SELECT 
    c.City,
    ca.CategoryName,
    COUNT(DISTINCT o.OrderID) AS Total_Orders,
    ROUND(SUM(od.TotalSales), 2) AS Total_Sales
FROM 
    orders o
JOIN 
    customers c ON o.CustomerID = c.CustomerID
JOIN 
    order_details od ON o.OrderID = od.OrderID
JOIN 
    products p ON od.ProductID = p.ProductID
JOIN 
    categories ca ON p.CategoryID = ca.CategoryID
GROUP BY 
    c.City, ca.CategoryName
ORDER BY 
    Total_Sales DESC;

-- How frequently do different customer segments place orders?

SELECT 
    c.City AS Customer_Segment,
    COUNT(DISTINCT o.OrderID) AS Total_Orders,
    COUNT(DISTINCT c.CustomerID) AS Total_Customers,
    ROUND(COUNT(DISTINCT o.OrderID) / COUNT(DISTINCT c.CustomerID), 2) AS Avg_Orders_Per_Customer
FROM 
    orders o
JOIN 
    customers c ON o.CustomerID = c.CustomerID
GROUP BY 
    c.City
ORDER BY 
    Total_Orders DESC;

-- What is the geographic and title-wise distribution of employees?

select Country,City,Title as Job_Title,count(*) as Num_Emp
from employees 
group by Country,City,Title
order by num_Emp desc;

-- What trends can we observe in hire dates across employee titles?

SELECT 
    e.Title AS Job_Title,
    YEAR(e.HireDate) AS Hire_Year,
    COUNT(*) AS Num_Hires
FROM 
    Employees e
GROUP BY 
    e.Title, YEAR(e.HireDate)
ORDER BY 
    Hire_Year, Job_Title;

-- What patterns exist in employee title and courtesy title distributions?

select Title as job_title,TitleOfCourtesy,count(*) as Num_Employees
from employees
group by job_title,TitleOfCourtesy
order by Num_Employees desc;

-- Are there correlations between product pricing, stock levels, and sales performance?

select p.ProductID,p.ProductName,p.UnitPrice,p.UnitsInStock,sum(od.Quantity)as Tot_Qty_Sold,
round(sum(od.TotalSales),2) as Total_sales
from products p 
join order_details od on p.ProductID=od.ProductID
group by p.ProductID,p.ProductName,p.UnitPrice,p.UnitsInStock
order by Total_sales desc;

-- How does product demand change over months or seasons?

SELECT 
    p.ProductName,
    DATE_FORMAT(o.OrderDate, '%Y-%m') AS Order_Month,
    SUM(od.Quantity) AS Total_Units_Sold,
    ROUND(SUM(od.TotalSales), 2) AS Total_Sales
FROM 
    Orders o
JOIN 
    Order_Details od ON o.OrderID = od.OrderID
JOIN 
    Products p ON od.ProductID = p.ProductID
GROUP BY 
    p.ProductName, Order_Month
ORDER BY 
    Order_Month, Total_Sales DESC;

-- Can we identify anomalies in product sales or revenue performance?

WITH MonthlySales AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        DATE_FORMAT(o.OrderDate, '%Y-%m') AS Order_Month,
        SUM(od.Quantity) AS Total_Units_Sold,
        ROUND(SUM(od.TotalSales), 2) AS Total_Sales
    FROM Orders o
    JOIN Order_Details od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName, Order_Month
)
SELECT
    ProductID,
    ProductName,
    Order_Month,
    Total_Units_Sold,
    Total_Sales,
    AVG(Total_Units_Sold) OVER (PARTITION BY ProductID) AS Avg_Units_Sold,
    ROUND(AVG(Total_Sales) OVER (PARTITION BY ProductID), 2) AS Avg_Sales
FROM MonthlySales
ORDER BY ProductID, Order_Month;

-- Are there any regional trends in supplier distribution and pricing?

SELECT 
    s.Country AS Region,
    COUNT(DISTINCT s.SupplierID) AS Num_Suppliers,
    ROUND(AVG(p.UnitPrice), 2) AS Avg_Product_Price
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
GROUP BY s.Country
ORDER BY Num_Suppliers DESC;

-- How are suppliers distributed across different product categories?

SELECT 
    c.CategoryName,
    COUNT(DISTINCT p.SupplierID) AS Num_Suppliers,
    COUNT(p.ProductID) AS Total_Products
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
ORDER BY Num_Suppliers DESC;

-- How do supplier pricing and categories relate across different regions?

SELECT 
    s.Country AS Region,
    c.CategoryName,
    COUNT(DISTINCT s.SupplierID) AS Num_Suppliers,
    COUNT(p.ProductID) AS Total_Products,
    ROUND(AVG(p.UnitPrice), 2) AS Avg_Product_Price,
    MIN(p.UnitPrice) AS Min_Price,
    MAX(p.UnitPrice) AS Max_Price
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY s.Country, c.CategoryName
ORDER BY s.Country, Avg_Product_Price DESC;

----------------------------------------------------------------------------------
-- Additional Analysis

--  Top Customers by Revenue Contribution

SELECT 
    c.CustomerID,
    c.CompanyName,
    COUNT(DISTINCT o.OrderID) AS Total_Orders,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS Total_Revenue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN Order_Details od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY Total_Revenue DESC
LIMIT 10;  

-- Order Frequency by Weekday or Month

-- Orders by weekday
SELECT 
    DAYNAME(OrderDate) AS Weekday,
    COUNT(OrderID) AS Total_Orders
FROM Orders
GROUP BY Weekday
ORDER BY FIELD(Weekday,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- Orders by month
SELECT 
    DATE_FORMAT(OrderDate, '%Y-%m') AS Order_Month,
    COUNT(OrderID) AS Total_Orders
FROM Orders
GROUP BY Order_Month
ORDER BY Order_Month;

-- Employee Contribution to Sales

SELECT 
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    COUNT(DISTINCT o.OrderID) AS Total_Orders,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS Total_Revenue
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN Order_Details od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, EmployeeName
ORDER BY Total_Revenue DESC;

-- Which suppliers fulfill the highest volume of products?

SELECT 
    s.SupplierID,
    s.CompanyName AS SupplierName,
    SUM(od.Quantity) AS Total_Units_Supplied,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS Total_Revenue
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
JOIN Order_Details od ON p.ProductID = od.ProductID
GROUP BY s.SupplierID, SupplierName
ORDER BY Total_Units_Supplied DESC
LIMIT 10;  

