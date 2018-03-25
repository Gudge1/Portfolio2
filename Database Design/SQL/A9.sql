CREATE TRIGGER [dbo].[A9]
ON [dbo].[DETAILRENTAL]
AFTER UPDATE
AS
BEGIN
	IF(EXISTS (SELECT * FROM DELETED) AND EXISTS(SELECT * FROM INSERTED))
	BEGIN
		DECLARE UPDATECURSOR CURSOR FOR 
		SELECT I.RENT_NUM, I.DETAIL_DUEDATE, I.DETAIL_RETURNDATE, I.DETAIL_DAILYLATEFEE, D.DETAIL_DUEDATE, D.DETAIL_RETURNDATE, D.DETAIL_DAILYLATEFEE
		FROM   INSERTED I INNER JOIN DELETED D ON I.RENT_NUM = D.RENT_NUM AND I.VID_NUM = D.VID_NUM

		DECLARE @RENT_NUM INT
		DECLARE @RETURN_DATE_NEW DATETIME
		DECLARE @RETURN_DATE_OLD DATETIME
		DECLARE @DUE_DATE_OLD DATETIME
		DECLARE @DUE_DATE_NEW DATETIME
		DECLARE @DAILY_LATE_FEE_NEW DECIMAL (4,2)
		DECLARE @DAILY_LATE_FEE_OLD DECIMAL (4,2)
		DECLARE @LATE_FEE_BEFORE DECIMAL (4,2)
		DECLARE @LATE_FEE_AFTER DECIMAL (4,2)
		DECLARE @DIFFERENCE DECIMAL (4,2)

		OPEN UPDATECURSOR
		FETCH NEXT FROM UPDATECURSOR
		INTO @RENT_NUM, @DUE_DATE_NEW, @RETURN_DATE_NEW, @DAILY_LATE_FEE_NEW, @DUE_DATE_OLD, @RETURN_DATE_OLD, @DAILY_LATE_FEE_OLD
		
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			IF(@RETURN_DATE_OLD > @DUE_DATE_OLD)
				SELECT @LATE_FEE_BEFORE = DATEDIFF(DAY, @DUE_DATE_OLD, @RETURN_DATE_OLD) * @DAILY_LATE_FEE_OLD
			ELSE
				SELECT @LATE_FEE_BEFORE = 0

			IF(@RETURN_DATE_NEW > @DUE_DATE_NEW)
				SELECT @LATE_FEE_AFTER = DATEDIFF(DAY, @DUE_DATE_NEW, @RETURN_DATE_NEW) * @DAILY_LATE_FEE_NEW
			ELSE
				SELECT @LATE_FEE_AFTER = 0

			SELECT @DIFFERENCE = @LATE_FEE_AFTER - @LATE_FEE_BEFORE

			IF(@DIFFERENCE <> 0)
			BEGIN
				DECLARE @MEM_NUM INT
				SELECT @MEM_NUM = M.MEM_NUM
				FROM RENTAL R INNER JOIN MEMBERSHIP M ON R.MEM_NUM = M.MEM_NUM AND R.RENT_NUM = @RENT_NUM

				UPDATE MEMBERSHIP
					SET MEM_BALANCE = MEM_BALANCE + @DIFFERENCE
					WHERE MEM_NUM = @MEM_NUM
			END

			FETCH NEXT FROM UPDATECURSOR
			INTO @RENT_NUM, @DUE_DATE_NEW, @RETURN_DATE_NEW, @DAILY_LATE_FEE_NEW, @DUE_DATE_OLD, @RETURN_DATE_OLD, @DAILY_LATE_FEE_OLD

		END

		CLOSE UPDATECURSOR
		DEALLOCATE UPDATECURSOR
	END
END

UPDATE DETAILRENTAL
SET DETAIL_RETURNDATE = '2013-03-07'
WHERE RENT_NUM = 1006 OR RENT_NUM = 1007

UPDATE DETAILRENTAL
SET DETAIL_RETURNDATE = '2013-03-05'
WHERE RENT_NUM = 1006 OR RENT_NUM = 1007

UPDATE MEMBERSHIP
SET MEM_BALANCE = 1.00

SELECT *
FROM MEMBERSHIP

SELECT *
FROM  DETAILRENTAL

SELECT *
FROM RENTAL

DROP TRIGGER A9
