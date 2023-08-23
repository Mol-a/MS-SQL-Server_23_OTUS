/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
Select *From Application.People
Select *From Sales.Invoices
Select *From Sales.InvoiceLines
--IsSalesPerson=1 - поле в Application.People, указывающее на то, что человек явля-ся продажником
--проверяемый запрос
SELECT
	ap.PersonID
	,si.SalespersonPersonID
	,ap.FullName
	,si.InvoiceDate
	,ap.IsSalesperson
	,si.SalesCount
FROM
	Application.People ap
	 left join (Select count(InvoiceId)  AS SalesCount, InvoiceDate, SalespersonPersonID
		FROM Sales.Invoices si
		WHERE --si.SalespersonPersonID = ap.PersonID and
		si.InvoiceDate = '2015.04.01'
		group by si.InvoiceDate, si.SalespersonPersonID) as si
		on ap.PersonID = si.SalespersonPersonID
WHERE si.SalespersonPersonID is null and  IsSalesperson = 1 
--находим сотрудников, которые являются продажниками (IsSalesperson = 1)
SELECT
	ap.PersonID
	,ap.FullName
	,ap.IsSalesperson
FROM Application.People ap
WHERE IsSalesperson = 1
---Выполнение задания 1
--находим продажников, которые сделали n-количество заказов в дату'2015.04.01'
Select 
	count(InvoiceId)  AS SalesCount
	,InvoiceDate
	,SalespersonPersonID
FROM Sales.Invoices si
WHERE si.InvoiceDate = '2015.04.01'
GROUP BY si.InvoiceDate, si.SalespersonPersonID

--вариант 1 (подзапросом)
SELECT
	ap.PersonID
	,ap.FullName
FROM Application.People ap
left join (
			Select 
				count(InvoiceId)  AS SalesCount
				,InvoiceDate
				,SalespersonPersonID
			FROM Sales.Invoices si
			WHERE si.InvoiceDate = '2015.04.01'
			GROUP BY si.InvoiceDate, si.SalespersonPersonID) as si_new
ON ap.PersonID = si_new.SalespersonPersonID
WHERE IsSalesperson = 1 and si_new.SalespersonPersonID is null

--вариант 2 (CTE)
WITH InvoicesCTE (SalespersonPersonID,InvoiceDate,SalesCount) AS
(Select 
		SalespersonPersonID, InvoiceDate, Count(InvoiceId)  AS SalesCount
FROM Sales.Invoices si
WHERE si.InvoiceDate = '2015.04.01'
GROUP BY si.InvoiceDate, si.SalespersonPersonID)
SELECT
	ap.PersonID
	,i.SalespersonPersonID
	,i.InvoiceDate, i.SalesCount, ap.FullName, ap.IsSalesperson
FROM Application.People ap
 LEFT JOIN InvoicesCTE AS I
		ON ap.PersonID = I.SalespersonPersonID
WHERE ap.IsSalesperson = 1 and I.SalespersonPersonID is null;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT * FROM Sales.InvoiceLines
Order BY UnitPrice 
--товары с минимальной ценой
SELECT * FROM Warehouse.StockItems
Order BY UnitPrice

--вариант 1 с подзапросом
SELECT si.StockItemID, si.Description, si.UnitPrice
FROM Sales.InvoiceLines as si
WHERE si.UnitPrice = (SELECT MIN(UnitPrice)
					FROM Warehouse.StockItems as ws)
--вариант 2 с СТЕ
WITH UnitPriceCTE (UnitPrice) as
(Select top 1 UnitPrice
FROM Sales.InvoiceLines as si
ORDER BY UnitPrice)
SELECT ws.StockItemID, ws.StockItemName, ws.UnitPrice
FROM Warehouse.StockItems as ws
join UnitPriceCTE as upc
ON ws.UnitPrice = upc.UnitPrice


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

Select * From Sales.CustomerTransactions
ORDER BY CustomerID
--анализ таблиц
SELECT *FROM Sales.CustomerTransactions --TransactionAmount
SELECT *FROM Sales.Customers			--Customer Name, PhoneNumber, WebsiteURL
--упорядочиваю клиентов по максимальным платежам
SELECT CustomerID, count(TransactionAmount) FROM Sales.CustomerTransactions
Order by CustomerID asc,TransactionAmount desc

--пытаюсь у каждого клиента отобрать по 5 первым (максимальным) платежам
WITH Price5Top(CustomerID, TransactionAmount) as
(SELECT CustomerID, TransactionAmount FROM Sales.CustomerTransactions
Order by CustomerID asc,TransactionAmount desc)-- нельзя использовать в подзапросах

--ДАЙТЕ ПОДСКАЗКУ КАК ОТОБРАТЬ 5 максимальных платежей каждого клиента? 



--информация о 5 клиентах, которые перевели компании максимальные платежи
--вариант1
SELECT DISTINCT
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber 
FROM 
	(
		SELECT TOP 5 CustomerID
		FROM Sales.CustomerTransactions 
		ORDER BY TransactionAmount DESC
	) T
	INNER JOIN Sales.Customers c ON T.CustomerID = c.CustomerID;
--вариант 2
SELECT DISTINCT
	 CustomerID
	,CustomerName
	,PhoneNumber 
FROM Sales.Customers
WHERE
	CustomerID IN
	(
		SELECT  CustomerID
		FROM Sales.CustomerTransactions 
		ORDER BY TransactionAmount DESC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
	);

--вариант 3
WITH Price5Top AS
(
	SELECT TOP 5
		 CustomerID
		,TransactionAmount
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)
SELECT DISTINCT
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber 
FROM
	Sales.Customers c 
	INNER JOIN Price5Top p ON c.CustomerID = p.CustomerID


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
SELECT DISTINCT
	 cts.CityID
	,cts.CityName
	,p.FullName
FROM
	(
		SELECT TOP 3 StockItemID
		FROM Warehouse.StockItems
		ORDER BY UnitPrice DESC
	) si
	INNER JOIN Sales.OrderLines ol ON si.StockItemID = ol.StockItemID
	INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
	INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
	INNER JOIN Application.People p ON o.PickedByPersonID = p.PersonID
	INNER JOIN Application.Cities cts ON c.DeliveryCityID = cts.CityID


--

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

