--Müşteri hesap hareketlerini tutacak tabloyu oluşturur (Ana Tabel'ları oluşturmadan çalıştıramazsınız !)
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    TransactionType NVARCHAR(20) CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'BetWin')),
    Amount DECIMAL(10, 2) NOT NULL,
    TransactionDate DATETIME DEFAULT GETDATE()
);

-- Günlük toplam bahis miktarını hesaplayan metod : 
CREATE FUNCTION fn_DailyTotalBets (@Date DATE)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @Total DECIMAL(10, 2);
    SELECT @Total = SUM(BetAmount)
    FROM Bets
    WHERE CAST(BetDate AS DATE) = @Date;
    RETURN ISNULL(@Total, 0);
END;

-- Bir müşterinin toplam kazançlarını hesaplayan method :
CREATE FUNCTION fn_CustomerTotalWinnings (@CustomerID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @Total DECIMAL(10, 2);
    SELECT @Total = SUM(Winnings)
    FROM Bets
    WHERE CustomerID = @CustomerID AND Outcome = 'Win';
    RETURN ISNULL(@Total, 0);
END;

-- Müşteri bakiyesini hesaplayan fonksiyon : 
CREATE FUNCTION fn_CustomerBalance (@CustomerID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @Deposits DECIMAL(10, 2);
    DECLARE @Withdrawals DECIMAL(10, 2);
    DECLARE @BetWinnings DECIMAL(10, 2);

    SELECT @Deposits = ISNULL(SUM(Amount), 0)
    FROM Transactions
    WHERE CustomerID = @CustomerID AND TransactionType = 'Deposit';

    SELECT @Withdrawals = ISNULL(SUM(Amount), 0)
    FROM Transactions
    WHERE CustomerID = @CustomerID AND TransactionType = 'Withdrawal';

    SELECT @BetWinnings = ISNULL(SUM(Amount), 0)
    FROM Transactions
    WHERE CustomerID = @CustomerID AND TransactionType = 'BetWin';

    RETURN @Deposits + @BetWinnings - @Withdrawals;
END;

-- Yeni bahis ekleme prosedürü ve müşteri bakiyesini kontrol etme islemi :
CREATE PROCEDURE sp_AddBet
    @CustomerID INT,
    @BetAmount DECIMAL(10, 2),
    @Outcome NVARCHAR(10)
AS
BEGIN
    DECLARE @DailyTotal DECIMAL(10, 2);
    DECLARE @CustomerBalance DECIMAL(10, 2);
    
    SET @DailyTotal = dbo.fn_DailyTotalBets(CAST(GETDATE() AS DATE));
    SET @CustomerBalance = dbo.fn_CustomerBalance(@CustomerID);
    
    IF @CustomerBalance < @BetAmount
    BEGIN
        RAISERROR('Insufficient balance.', 16, 1);
        RETURN;
    END

    IF @DailyTotal + @BetAmount > 10000
    BEGIN
        RAISERROR('Daily betting limit exceeded.', 16, 1);
        RETURN;
    END
    
    INSERT INTO Bets (CustomerID, BetAmount, BetDate, Outcome)
    VALUES (@CustomerID, @BetAmount, GETDATE(), @Outcome);

    IF @Outcome = 'Win'
    BEGIN
        DECLARE @Winnings DECIMAL(10, 2);
        SET @Winnings = @BetAmount * 2;

        INSERT INTO Transactions (CustomerID, TransactionType, Amount, TransactionDate)
        VALUES (@CustomerID, 'BetWin', @Winnings, GETDATE());
    END
END;

-- Bahis sonucu güncellendiği zamsn müşteri kazançlarını ve hesap hareketlerini güncelleyen trigger : 
CREATE TRIGGER trg_UpdateCustomerWinnings
ON Bets
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Outcome)
    BEGIN
        DECLARE @CustomerID INT;
        DECLARE @BetID INT;
        DECLARE @NewOutcome NVARCHAR(10);
        DECLARE @OldOutcome NVARCHAR(10);
        DECLARE @BetAmount DECIMAL(10, 2);
        
        SELECT @CustomerID = inserted.CustomerID, 
               @BetID = inserted.BetID, 
               @NewOutcome = inserted.Outcome,
               @BetAmount = inserted.BetAmount
        FROM inserted;
        
        SELECT @OldOutcome = deleted.Outcome
        FROM deleted
        WHERE deleted.BetID = @BetID;
        
        IF @OldOutcome = 'Win' AND @NewOutcome <> 'Win'
        BEGIN
            DELETE FROM Transactions
            WHERE CustomerID = @CustomerID AND TransactionType = 'BetWin' AND Amount = @BetAmount * 2;
        END

        IF @NewOutcome = 'Win'
        BEGIN
            INSERT INTO Transactions (CustomerID, TransactionType, Amount, TransactionDate)
            VALUES (@CustomerID, 'BetWin', @BetAmount * 2, GETDATE());
        END
    END
END;

--Müşterilerin son 30 gündeki bahis ve kazanç özetini getiren query : 
SELECT 
    C.CustomerID, 
    C.FirstName, 
    C.LastName, 
    SUM(B.BetAmount) AS TotalBets, 
    SUM(B.Winnings) AS TotalWinnings,
    COUNT(B.BetID) AS BetCount
FROM Customers C
LEFT JOIN Bets B ON C.CustomerID = B.CustomerID
WHERE B.BetDate >= DATEADD(DAY, -30, GETDATE())
GROUP BY C.CustomerID, C.FirstName, C.LastName
ORDER BY TotalWinnings DESC;

-- Aktif olmayan müşterileri getiren query (son 6 ayda bahis yapmamış oe) : 
SELECT 
    C.CustomerID, 
    C.FirstName, 
    C.LastName, 
    C.Email, 
    MAX(B.BetDate) AS LastBetDate
FROM Customers C
LEFT JOIN Bets B ON C.CustomerID = B.CustomerID
GROUP BY C.CustomerID, C.FirstName, C.LastName, C.Email
HAVING MAX(B.BetDate) < DATEADD(MONTH, -6, GETDATE()) OR MAX(B.BetDate) IS NULL
ORDER BY LastBetDate;

-- En çok kazanan müşteriyi getiren query :
SELECT TOP 1
    C.CustomerID, 
    C.FirstName, 
    C.LastName, 
    dbo.fn_CustomerTotalWinnings(C.CustomerID) AS TotalWinnings
FROM Customers C
ORDER BY TotalWinnings DESC;
