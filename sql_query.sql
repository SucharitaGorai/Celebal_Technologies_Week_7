CREATE TABLE DimCustomer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerCode VARCHAR(50),
    Name VARCHAR(100),
    Email VARCHAR(100),
    StartDate DATETIME,
    EndDate DATETIME,
    IsCurrent BIT,
    PreviousEmail VARCHAR(100)
);

CREATE TABLE DimCustomer_History (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode VARCHAR(50),
    Name VARCHAR(100),
    Email VARCHAR(100),
    ChangedDate DATETIME
);



CREATE PROCEDURE SCD_Type_0_Insert
    @CustomerCode VARCHAR(50),
    @Name VARCHAR(100),
    @Email VARCHAR(100)
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM DimCustomer WHERE CustomerCode = @CustomerCode
    )
    BEGIN
        INSERT INTO DimCustomer (CustomerCode, Name, Email, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerCode, @Name, @Email, GETDATE(), NULL, 1)
    END
    ELSE
    BEGIN
        PRINT 'Change not allowed for SCD Type 0.'
    END
END

EXEC SCD_Type_0_Insert 'C001', 'John Doe', 'john@example.com'
EXEC SCD_Type_0_Insert 'C001', 'John Updated', 'john.updated@example.com'


CREATE PROCEDURE SCD_Type_1_Update
    @CustomerCode VARCHAR(50),
    @Name VARCHAR(100),
    @Email VARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM DimCustomer WHERE CustomerCode = @CustomerCode
    )
    BEGIN
        UPDATE DimCustomer
        SET Name = @Name,
            Email = @Email
        WHERE CustomerCode = @CustomerCode
    END
    ELSE
    BEGIN
        INSERT INTO DimCustomer (CustomerCode, Name, Email, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerCode, @Name, @Email, GETDATE(), NULL, 1)
    END
END

EXEC SCD_Type_1_Update 'C004', 'Alice Jones', 'alice@example.com'
EXEC SCD_Type_1_Update 'C004', 'Alice J.', 'alice.j@example.com'





CREATE PROCEDURE SCD_Type_2_Update
    @CustomerCode VARCHAR(50),
    @Name VARCHAR(100),
    @Email VARCHAR(100)
AS
BEGIN
    DECLARE @ExistingID INT

    SELECT @ExistingID = CustomerID
    FROM DimCustomer
    WHERE CustomerCode = @CustomerCode AND IsCurrent = 1

    IF @ExistingID IS NOT NULL
    BEGIN
        UPDATE DimCustomer
        SET EndDate = GETDATE(), IsCurrent = 0
        WHERE CustomerID = @ExistingID

        INSERT INTO DimCustomer (CustomerCode, Name, Email, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerCode, @Name, @Email, GETDATE(), NULL, 1)
    END
    ELSE
    BEGIN
        INSERT INTO DimCustomer (CustomerCode, Name, Email, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerCode, @Name, @Email, GETDATE(), NULL, 1)
    END
END

EXEC SCD_Type_2_Update 'C002', 'Alice Smith', 'alice@example.com'
EXEC SCD_Type_2_Update 'C002', 'Alice Johnson', 'alice.johnson@example.com'

CREATE PROCEDURE SCD_Type_3_Update
    @CustomerCode VARCHAR(50),
    @Name VARCHAR(100),
    @Email VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM DimCustomer WHERE CustomerCode = @CustomerCode)
    BEGIN
        UPDATE DimCustomer
        SET PreviousEmail = Email,
            Email = @Email,
            Name = @Name
        WHERE CustomerCode = @CustomerCode
    END
    ELSE
    BEGIN
        INSERT INTO DimCustomer (CustomerCode, Name, Email, PreviousEmail, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerCode, @Name, @Email, NULL, GETDATE(), NULL, 1)
    END
END

EXEC SCD_Type_3_Update 'C003', 'Bob Smith', 'bob@example.com'
EXEC SCD_Type_3_Update 'C003', 'Bob Smith', 'bob.smith@example.com'


CREATE PROCEDURE SCD_Type_4_Update
    @CustomerCode VARCHAR(50),
    @Name VARCHAR(100),
    @Email VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM DimCustomer WHERE CustomerCode = @CustomerCode)
    BEGIN
        -- Move current record to history table
        INSERT INTO DimCustomerHistory (CustomerCode, Name, Email, ArchivedDate)
        SELECT CustomerCode, Name, Email, GETDATE()
        FROM DimCustomer
        WHERE CustomerCode = @CustomerCode;

        -- Update current dimension with new values
        UPDATE DimCustomer
        SET Name = @Name,
            Email = @Email
        WHERE CustomerCode = @CustomerCode;
    END
    ELSE
    BEGIN
        -- Insert new record into DimCustomer if not exists
        INSERT INTO DimCustomer (CustomerCode, Name, Email)
        VALUES (@CustomerCode, @Name, @Email);
    END
END


EXEC SCD_Type_4_Update 'C004', 'Alice Cooper', 'alice@example.com'
EXEC SCD_Type_4_Update 'C004', 'Alice Cooper', 'alice.updated@example.com'

CREATE PROCEDURE SCD_Type_6_Update
    @CustomerCode VARCHAR(50),
    @Name VARCHAR(100),
    @Email VARCHAR(100)
AS
BEGIN
    DECLARE @ExistingID INT, @OldEmail VARCHAR(100)

    SELECT TOP 1
        @ExistingID = CustomerID,
        @OldEmail = Email
    FROM DimCustomer
    WHERE CustomerCode = @CustomerCode AND IsCurrent = 1

    IF @ExistingID IS NOT NULL
    BEGIN
        UPDATE DimCustomer
        SET EndDate = GETDATE(), IsCurrent = 0
        WHERE CustomerID = @ExistingID

        INSERT INTO DimCustomer (CustomerCode, Name, Email, PreviousEmail, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerCode, @Name, @Email, @OldEmail, GETDATE(), NULL, 1)
    END
    ELSE
    BEGIN
        INSERT INTO DimCustomer (CustomerCode, Name, Email, PreviousEmail, StartDate, EndDate, IsCurrent)
        VALUES (@CustomerCode, @Name, @Email, NULL, GETDATE(), NULL, 1)
    END
END

EXEC SCD_Type_6_Update 'C006', 'Jane Smith', 'jane@example.com';
EXEC SCD_Type_6_Update 'C006', 'Jane Smith', 'jane.smith@newmail.com';


