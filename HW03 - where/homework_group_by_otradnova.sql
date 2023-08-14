/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
	Year (si.InvoiceDate) [Year_Sale], -- Год продажи (например, 2015)
	MONTH (si.InvoiceDate) [Mont_Sale], -- Месяц продажи (например, 4)
	AVG (sil.UnitPrice) [AVG_MonthPrice], --Средняя цена за месяц по всем товарам
	SUM (sil.UnitPrice * sil.Quantity) [Total_MonthSales] --Общая сумма продаж за месяц
From Sales.Invoices as si join Sales.InvoiceLines as sil on si.InvoiceID=sil.InvoiceID
Group by Year (si.InvoiceDate), Month(si.InvoiceDate)
Order by Year (si.InvoiceDate), Month(si.InvoiceDate)

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
Select 
	Year (si.InvoiceDate) [Year_Sale], -- Год продажи (например, 2015)
	MONTH (si.InvoiceDate) [Mont_Sale], -- Месяц продажи (например, 4)
	SUM (sil.UnitPrice * sil.Quantity) [Total_MonthSales] --Общая сумма продаж за месяц
From Sales.Invoices as si join Sales.InvoiceLines as sil on si.InvoiceID=sil.InvoiceID
Group by Year (si.InvoiceDate), Month(si.InvoiceDate)
Having SUM (sil.UnitPrice * sil.Quantity) > 4600000
Order by Year (si.InvoiceDate), Month(si.InvoiceDate)

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи --TransactionAmount
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
--SELECT *FROM SALES.InvoiceLines Where StockItemID=1
--SELECT *FROM SALES.Invoices
--SELECT *FROM Warehouse.StockItems
--SELECT *FROM Sales.CustomerTransactions 

--Пробуем найти по одному товару кол-во по месяцам и общую сумму продажи
--SELECT *
--FROM SALES.InvoiceLines sil join SALES.Invoices si on sil.InvoiceID=si.InvoiceID  Where sil.StockItemID=1
--Order by si.InvoiceDate

--Запрос по условиям в части одного товара
--SELECT sil.StockItemID, sum(sil.Quantity) [QUANTITY_Sales], sum(sil.Quantity*sil.UnitPrice) [Sales] ,MONTH(si.InvoiceDate) [Month],YEAR(si.InvoiceDate)[Year],MIN(si.InvoiceDate) [First_Sales]
--FROM SALES.InvoiceLines sil join SALES.Invoices si on sil.InvoiceID=si.InvoiceID 
--Where sil.StockItemID=1
--Group by  sil.StockItemID, MONTH(si.InvoiceDate),YEAR(si.InvoiceDate)
--ORDER BY sil.StockItemID, MONTH(si.InvoiceDate),YEAR(si.InvoiceDate)


--РЕШЕНИЕ 1
SELECT sil.StockItemID, ws.StockItemName, sum(sil.Quantity) [QUANTITY_Sales], sum(sil.Quantity*sil.UnitPrice) [Sales] ,MONTH(si.InvoiceDate) [Month],YEAR(si.InvoiceDate)[Year],MIN(si.InvoiceDate) [First_Sales]
FROM SALES.InvoiceLines sil join SALES.Invoices si on sil.InvoiceID=si.InvoiceID 
join Warehouse.StockItems ws on sil.StockItemID=ws.StockItemID
Group by  sil.StockItemID,ws.StockItemName, MONTH(si.InvoiceDate),YEAR(si.InvoiceDate)
Having sum(sil.Quantity) < 50
ORDER BY sil.StockItemID, MONTH(si.InvoiceDate),YEAR(si.InvoiceDate)


--РЕШЕНИЕ 2 (соединяем другие таблицы, более легкий запрос 11% по сравнению с решением 1) 
SELECT 
	ws.StockItemID [Items],
	ws.StockItemName [Name],
	YEAR(ct.TransactionDate) [YEAR_SALE],
	Month(ct.TransactionDate) [MONTH_SALE],
	SUM(sil.UnitPrice * sil.Quantity) [SALES_SUM],
	Min(ct.TransactionDate) [FIRST_DATE_SALES],
	SUM (sil.Quantity) [QUANTITY_SALES]
FROM Sales.InvoiceLines sil
join Warehouse.StockItems ws on sil.StockItemID=ws.StockItemID
join Sales.CustomerTransactions ct on sil.InvoiceID=ct.InvoiceID
GROUP BY
	ws.StockItemID,
	ws.StockItemName,
	YEAR(ct.TransactionDate),
	Month(ct.TransactionDate)
HAVING SUM (sil.Quantity) < 50
ORDER BY ws.StockItemID
		,YEAR(ct.TransactionDate),
		Month(ct.TransactionDate)
	
--РЕШЕНИЕ 3 (Сумма продажи берем из таблицы Sales.CustomerTransactions)
SELECT 
	 si.StockItemID
	,si.StockItemName
	,YEAR(ct.TransactionDate) [Year_Sale]
	,month(ct.TransactionDate) AS [Month]
	,SUM(ct.TransactionAmount) AS [Sales Sum]
	,MIN(ct.TransactionDate) AS [First Sale]
	,SUM (il.Quantity) AS [Sales Quantity]
FROM
	Sales.InvoiceLines il
	INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
	INNER JOIN Sales.CustomerTransactions ct ON il.InvoiceID = ct.InvoiceID
GROUP BY
	 si.StockItemID
	,si.StockItemName
	,year(ct.TransactionDate)
	,month(ct.TransactionDate)
HAVING SUM(il.Quantity) < 50
ORDER BY
	 si.StockItemID ASC
	,YEAR_SALE
	,Month ASC;


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
