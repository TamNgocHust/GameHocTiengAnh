Create Database GameHocTiengAnh1
on
(   Name = 'gametienganh_data',
    filename = 'E:\BaiTapLonKTPM\gametienganh1_data.mdf',
    size = 200mb,
    maxsize = 10000mb,
    filegrowth=100mb
)
log on 
(
   Name = 'gametienganh_log',
   filename = 'E:\BaiTapLonKTPM\gametienganh1_log.ldf',
   size = 100mb,
   maxsize = 2000mb,
   filegrowth=100mb
)

-- 1. Sử dụng Database của bạn (Nếu chưa có DB thì bỏ dòng này và tạo DB trước)
USE GameHocTiengAnh1; 
GO

-- 2. Tạo tài khoản đăng nhập vào Server (Tên: GameUser, Mật khẩu: 123456)
-- Lệnh này tự động BỎ QUA chính sách mật khẩu phức tạp
CREATE LOGIN GameUser WITH PASSWORD = '123456', CHECK_POLICY = OFF;
GO

-- 3. Tạo User trong Database từ tài khoản trên
CREATE USER GameUser FOR LOGIN GameUser;
GO

-- 4. Cấp quyền Đọc (Select) và Ghi (Insert/Update) cho User này
ALTER ROLE db_datareader ADD MEMBER GameUser;
ALTER ROLE db_datawriter ADD MEMBER GameUser;
GO

-- 5. Đảm bảo Server cho phép đăng nhập bằng tài khoản SQL (Mixed Mode)
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
    N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;
GO

PRINT '=== TẠO TÀI KHOẢN THÀNH CÔNG ===';
PRINT 'User: GameUser';
PRINT 'Pass: 123456';
SELECT @@SERVERNAME;
-- Sử dụng database vừa tạo
USE GameHocTiengAnh1;
GO

-- =================================================================
-- I. NHÓM BẢNG QUẢN LÝ NGƯỜI DÙNG
-- =================================================================

-- Bảng lưu trữ vai trò người dùng (Học sinh, Giáo viên, Admin)
CREATE TABLE Roles (
    RoleID INT PRIMARY KEY IDENTITY(1,1),
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);

-- Bảng chính lưu thông tin tài khoản
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(150),
    RoleID INT NOT NULL,
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);

-- Bảng Khối học
CREATE TABLE Grades (
    GradeID INT PRIMARY KEY IDENTITY(1,1),
    GradeName NVARCHAR(50) NOT NULL UNIQUE
);

-- Bảng Lớp học
CREATE TABLE Classes (
    ClassID INT PRIMARY KEY IDENTITY(1,1),
    ClassName NVARCHAR(50) NOT NULL,
    GradeID INT NOT NULL,
    TeacherID INT, -- Giáo viên chủ nhiệm
    FOREIGN KEY (GradeID) REFERENCES Grades(GradeID),
    FOREIGN KEY (TeacherID) REFERENCES Users(UserID)
);

-- Bảng thông tin mở rộng cho học sinh
CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    ClassID INT,
    AvatarURL NVARCHAR(255),
    FOREIGN KEY (StudentID) REFERENCES Users(UserID),
    FOREIGN KEY (ClassID) REFERENCES Classes(ClassID)
);


-- =================================================================
-- II. NHÓM BẢNG QUẢN LÝ NỘI DUNG
-- =================================================================

-- Bảng Chủ đề cho từ vựng và câu hỏi
CREATE TABLE Topics (
    TopicID INT PRIMARY KEY IDENTITY(1,1),
    TopicName NVARCHAR(100) NOT NULL
);

-- Bảng Từ vựng
CREATE TABLE Vocabulary (
    VocabID INT PRIMARY KEY IDENTITY(1,1),
    Word NVARCHAR(100) NOT NULL,
    WordType NVARCHAR(50), -- [MỚI] Loại từ (Danh từ, Động từ...)
    Meaning NVARCHAR(255),
    Pronunciation NVARCHAR(100),
    AudioURL NVARCHAR(255) NULL,
    ImageURL NVARCHAR(255) NULL,
    Example NVARCHAR(500),
    TopicID INT,
    FOREIGN KEY (TopicID) REFERENCES Topics(TopicID)
);

-- Tạo bảng Ngữ pháp
CREATE TABLE Grammar (
    GrammarID INT PRIMARY KEY IDENTITY(1,1),
    GrammarName NVARCHAR(150) NOT NULL, -- Tên (Vd: Câu hỏi tên)
    Structure NVARCHAR(MAX),            -- Công thức (Vd: What is your name?)
    Usage NVARCHAR(MAX),                -- Cách dùng (Vd: Dùng để hỏi tên người khác)
    Example NVARCHAR(MAX),              -- Ví dụ (Vd: My name is Lan.)
    Note NVARCHAR(MAX) ,                 -- Ghi chú thêm (nếu có)
    TopicID INT,                        -- Liên kết với Chủ đề
    FOREIGN KEY (TopicID) REFERENCES Topics(TopicID)
);

-- Bảng Câu hỏi
CREATE TABLE Questions (
    QuestionID INT PRIMARY KEY IDENTITY(1,1),
    GrammarID INT,
    QuestionText NVARCHAR(MAX),
    QuestionType NVARCHAR(50) NOT NULL, -- 'multiple_choice', 'fill_in_blank', 'scramble', 'matching'
    AudioURL NVARCHAR(255),
    ImageURL NVARCHAR(255), -- Hình ảnh cho câu hỏi
    TopicID INT,
    HintText NVARCHAR(255), -- Gợi ý khi bí bằng văn bản
    CorrectAnswer NVARCHAR(255),
    FOREIGN KEY (TopicID) REFERENCES Topics(TopicID),
    CONSTRAINT CK_QuestionType CHECK (QuestionType IN ('multiple_choice', 'fill_in_blank', 'scramble', 'matching')),
    CONSTRAINT FK_Questions_Grammar FOREIGN KEY (GrammarID) REFERENCES Grammar(GrammarID)
);

-- Bảng các phương án trả lời cho câu hỏi trắc nghiệm
CREATE TABLE QuestionOptions (
    OptionID INT PRIMARY KEY IDENTITY(1,1),
    QuestionID INT NOT NULL,
    OptionContent NVARCHAR(MAX) NOT NULL, -- Có thể là text hoặc URL ảnh
    IsCorrect BIT NOT NULL,
    FOREIGN KEY (QuestionID) REFERENCES Questions(QuestionID)
);

-- Bảng định nghĩa các Trò chơi/Bài tập
CREATE TABLE Games (
    GameID INT PRIMARY KEY IDENTITY(1,1),
    GameName NVARCHAR(150) NOT NULL,
    GameDescription NVARCHAR(500),
    TopicID INT,
    TimeLimit INT DEFAULT 0,  -- Thời gian chơi (giây). 0 là không giới hạn(chế độ luyện tập),>0 sẽ có tính thời gian(thử thách hơn)
    PassScore INT DEFAULT 5,  -- Điểm tối thiểu để qua màn
    FOREIGN KEY (TopicID) REFERENCES Topics(TopicID)
);

-- Bảng trung gian gán câu hỏi vào một trò chơi (quan hệ nhiều-nhiều)
CREATE TABLE Game_Questions (
    GameID INT,
    QuestionID INT,
    PRIMARY KEY (GameID, QuestionID),
    FOREIGN KEY (GameID) REFERENCES Games(GameID),
    FOREIGN KEY (QuestionID) REFERENCES Questions(QuestionID)
);


-- =================================================================
-- III. NHÓM BẢNG QUẢN LÝ KẾT QUẢ
-- =================================================================

-- Bảng Lịch sử chơi game của học sinh
CREATE TABLE PlayHistory (
    HistoryID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    GameID INT NOT NULL,
    Score INT NOT NULL,
    Stars INT NOT NULL,
    TimeTaken INT, -- Thời gian hoàn thành tính bằng giây
    PlayedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (StudentID) REFERENCES Users(UserID),
    FOREIGN KEY (GameID) REFERENCES Games(GameID),
    -- Ràng buộc logic dữ liệu
    CONSTRAINT CK_Score_Positive CHECK (Score >= 0),
    CONSTRAINT CK_Stars_Range CHECK (Stars BETWEEN 0 AND 3)
);

-- Index giúp lọc lịch sử của 1 học sinh nhanh hơn
CREATE INDEX IX_PlayHistory_Student ON PlayHistory(StudentID);

-- Bảng chi tiết câu trả lời của học sinh (Tùy chọn nhưng rất hữu ích)
CREATE TABLE StudentAnswers (
    AnswerID BIGINT PRIMARY KEY IDENTITY(1,1),
    HistoryID INT NOT NULL,
    QuestionID INT NOT NULL,
    SelectedAnswer NVARCHAR(MAX), -- Lưu câu trả lời của học sinh
    IsCorrect BIT NOT NULL,
    FOREIGN KEY (HistoryID) REFERENCES PlayHistory(HistoryID),
    FOREIGN KEY (QuestionID) REFERENCES Questions(QuestionID)
);

-- Bảng xếp hạng 
-- Lưu ý: Khi Code Backend xử lý chuyển lớp cho HS, phải update cả bảng này!
CREATE TABLE LeaderboardEntries (
    LeaderboardEntryID BIGINT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    ClassID INT NOT NULL,
    GradeID INT NOT NULL,
    TotalScore INT NOT NULL DEFAULT 0,
    TotalStars INT NOT NULL DEFAULT 0,
    RankMonth DATE NOT NULL, -- Ví dụ: Lưu ngày đầu tiên của tháng (2025-10-01)
    LastUpdated DATETIME DEFAULT GETDATE(),
    -- Đảm bảo mỗi học sinh chỉ có một bản ghi cho mỗi tháng
    CONSTRAINT UQ_LeaderboardEntry_StudentMonth UNIQUE (StudentID, RankMonth),
    FOREIGN KEY (StudentID) REFERENCES Users(UserID),
    FOREIGN KEY (ClassID) REFERENCES Classes(ClassID),
    FOREIGN KEY (GradeID) REFERENCES Grades(GradeID)
);

-- Index quan trọng để Sort bảng xếp hạng nhanh (VD: Lấy top 10 lớp 3A)
CREATE INDEX IX_Leaderboard_Sort ON LeaderboardEntries(ClassID, RankMonth, TotalScore DESC);

GO
-- =================================================================

CREATE TRIGGER UpdateLeaderboard_OnPlay
ON PlayHistory
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Khai báo biến bảng
    DECLARE @NetChanges TABLE (
        StudentID INT,
        RankMonth DATE,
        DeltaScore INT,
        DeltaStars INT
    );

    -- Tính toán Delta
    INSERT INTO @NetChanges (StudentID, RankMonth, DeltaScore, DeltaStars)
    SELECT 
        StudentID, 
        DATEFROMPARTS(YEAR(PlayedAt), MONTH(PlayedAt), 1),
        SUM(Score),
        SUM(Stars)
    FROM (
        SELECT StudentID, PlayedAt, Score, Stars FROM inserted
        UNION ALL
        SELECT StudentID, PlayedAt, -Score, -Stars FROM deleted
    ) AS AllChanges
    GROUP BY StudentID, DATEFROMPARTS(YEAR(PlayedAt), MONTH(PlayedAt), 1);

    -- Tạo dòng mới nếu chưa có
    INSERT INTO LeaderboardEntries (StudentID, ClassID, GradeID, RankMonth, TotalScore, TotalStars, LastUpdated)
    SELECT DISTINCT
        NC.StudentID,
        S.ClassID,
        C.GradeID,
        NC.RankMonth,
        0, 0, GETDATE()
    FROM @NetChanges NC
    JOIN Students S ON NC.StudentID = S.StudentID
    JOIN Classes C ON S.ClassID = C.ClassID
    WHERE NOT EXISTS (
        SELECT 1 FROM LeaderboardEntries LE 
        WHERE LE.StudentID = NC.StudentID AND LE.RankMonth = NC.RankMonth
    );

    -- Cập nhật điểm
    UPDATE LE
    SET 
        LE.TotalScore = LE.TotalScore + NC.DeltaScore,
        LE.TotalStars = LE.TotalStars + NC.DeltaStars,
        LE.LastUpdated = GETDATE()
    FROM LeaderboardEntries LE
    INNER JOIN @NetChanges NC 
        ON LE.StudentID = NC.StudentID AND LE.RankMonth = NC.RankMonth;
END;
GO

CREATE INDEX IX_Vocabulary_TopicID ON Vocabulary(TopicID);
CREATE INDEX IX_Questions_TopicID ON Questions(TopicID);
CREATE INDEX IX_Students_ClassID ON Students(ClassID);

-- TẠO DỮ LIỆU NỀN (ROLES & GRADES)
    INSERT INTO Roles (RoleName) VALUES ('student'),  ('admin'), ('teacher');

-- Tạo Khối học
INSERT INTO Grades (GradeName)
VALUES
    (N'Khối 1'),
    (N'Khối 2'),
    (N'Khối 3'),
    (N'Khối 4'),
    (N'Khối 5');
GO

-- KHAI BÁO BIẾN ĐỂ LẤY ROLE ID TỰ ĐỘNG
DECLARE @RoleAdminID INT = (SELECT RoleID FROM Roles WHERE RoleName = 'admin');
DECLARE @RoleTeacherID INT = (SELECT RoleID FROM Roles WHERE RoleName = 'teacher');
DECLARE @RoleStudentID INT = (SELECT RoleID FROM Roles WHERE RoleName = 'student');
INSERT INTO Users (Username, PasswordHash, FullName, RoleID) VALUES
--Thêm 3 tài khoản quản trị viên
    (N'admin1','admin',N'Tống Tâm Ngọc',@RoleAdminID),
    (N'admin2','admin',N'Vũ Việt Hoàng',@RoleAdminID),
    (N'admin3','admin',N'Hoàng Ngọc An',@RoleAdminID),
    -- Thêm tài khoản cho giáo viên 
    (N'teacher1','teacher',N'Nguyễn Văn A',@RoleTeacherID),
    (N'teacher2','teacher',N'Nguyễn Văn B',@RoleTeacherID),
    (N'teacher3','teacher',N'Nguyễn Văn C',@RoleTeacherID),
    (N'teacher4','teacher',N'Nguyễn Văn D',@RoleTeacherID);
-- Thêm tài khoản học sinh 
INSERT INTO Users (Username, PasswordHash, FullName, RoleID) VALUES
    (N'student1','student',N'Nguyễn Văn Phát',@RoleStudentID),
    (N'student2', 'student', N'Trần Thị Mai', @RoleStudentID),
    (N'student3', 'student', N'Lê Văn Hùng', @RoleStudentID),
    (N'student4', 'student', N'Phạm Minh Tuấn', @RoleStudentID),
    (N'student5', 'student', N'Hoàng Thị Lan', @RoleStudentID),
    (N'student6', 'student', N'Vũ Đức Thắng', @RoleStudentID),
    (N'student7', 'student', N'Đặng Thu Hà', @RoleStudentID),
    (N'student8', 'student', N'Bùi Văn Long', @RoleStudentID),
    (N'student9', 'student', N'Đỗ Thị Hương', @RoleStudentID),
    (N'student10', 'student', N'Ngô Văn Đạt', @RoleStudentID),
    (N'student11', 'student', N'Dương Thị Yến', @RoleStudentID),
    (N'student12', 'student', N'Lý Văn Nam', @RoleStudentID),
    (N'student13', 'student', N'Đinh Thị Tuyết', @RoleStudentID),
    (N'student14', 'student', N'Mai Phương Thúy', @RoleStudentID),
    (N'student15', 'student', N'Lương Thế Vinh', @RoleStudentID),
    (N'student16', 'student', N'Cao Thái Sơn', @RoleStudentID),
    (N'student17', 'student', N'Trương Quỳnh Anh', @RoleStudentID),
    (N'student18', 'student', N'Nguyễn Bảo Ngọc', @RoleStudentID),
    (N'student19', 'student', N'Trần Anh Tú', @RoleStudentID),
    (N'student20', 'student', N'Lê Quốc Khánh', @RoleStudentID),
    (N'student21', 'student', N'Phạm Gia Huy', @RoleStudentID),
    (N'student22', 'student', N'Hoàng Minh Trí', @RoleStudentID),
    (N'student23', 'student', N'Vũ Thùy Linh', @RoleStudentID),
    (N'student24', 'student', N'Đặng Ngọc Hân', @RoleStudentID),
    (N'student25', 'student', N'Bùi Tiến Dũng', @RoleStudentID),
    (N'student26', 'student', N'Đỗ Quang Hải', @RoleStudentID),
    (N'student27', 'student', N'Ngô Bảo Châu', @RoleStudentID),
    (N'student28', 'student', N'Dương Thúy Vi', @RoleStudentID),
    (N'student29', 'student', N'Lý Nhã Kỳ', @RoleStudentID),
    (N'student30', 'student', N'Đinh Tiến Dũng', @RoleStudentID),
    (N'student31', 'student', N'Nguyễn Công Phượng', @RoleStudentID),
    (N'student32', 'student', N'Trần Duy Hưng', @RoleStudentID),
    (N'student33', 'student', N'Lê Thẩm Dương', @RoleStudentID),
    (N'student34', 'student', N'Phạm Nhật Minh', @RoleStudentID),
    (N'student35', 'student', N'Hoàng Kiều Anh', @RoleStudentID),
    (N'student36', 'student', N'Vũ Cát Tường', @RoleStudentID),
    (N'student37', 'student', N'Đặng Lê Nguyên', @RoleStudentID),
    (N'student38', 'student', N'Bùi Anh Tuấn', @RoleStudentID),
    (N'student39', 'student', N'Đỗ Mỹ Linh', @RoleStudentID),
    (N'student40', 'student', N'Ngô Thanh Vân', @RoleStudentID);
GO

--*Chèn lớp:
-- Lấy ID của Khối 5
DECLARE @Grade5ID INT = (SELECT GradeID FROM Grades WHERE GradeName = N'Khối 5');

-- Lấy ID của các giáo viên (theo Username bạn đã tạo)
DECLARE @TeacherA_ID INT = (SELECT UserID FROM Users WHERE Username = 'teacher1');
DECLARE @TeacherB_ID INT = (SELECT UserID FROM Users WHERE Username = 'teacher2');
DECLARE @TeacherC_ID INT = (SELECT UserID FROM Users WHERE Username = 'teacher3');
DECLARE @TeacherD_ID INT = (SELECT UserID FROM Users WHERE Username = 'teacher4');

INSERT INTO Classes (ClassName, GradeID, TeacherID) VALUES 
        (N'Lớp 5A', @Grade5ID, @TeacherA_ID), -- GV Nguyễn Văn A
        (N'Lớp 5B', @Grade5ID, @TeacherB_ID), -- GV Nguyễn Văn B
        (N'Lớp 5C', @Grade5ID, @TeacherC_ID), -- GV Nguyễn Văn C
        (N'Lớp 5D', @Grade5ID, @TeacherD_ID); -- GV Nguyễn Văn D
GO
--Hàm thêm học sinh vào lớp
CREATE PROCEDURE AddStudentToClass
    @StudentUsername NVARCHAR(100),
    @ClassName NVARCHAR(50)
AS
BEGIN
    DECLARE @StudentID INT = (SELECT UserID FROM Users WHERE Username = @StudentUsername);
    DECLARE @ClassID INT = (SELECT ClassID FROM Classes WHERE ClassName = @ClassName);

    -- Kiểm tra dữ liệu hợp lệ
    IF @StudentID IS NULL 
    BEGIN
        PRINT N'Lỗi: Không tìm thấy user ' + @StudentUsername;
        RETURN;
    END

    IF @ClassID IS NULL 
    BEGIN
        PRINT N'Lỗi: Không tìm thấy lớp ' + @ClassName;
        RETURN;
    END

    -- Kiểm tra đã tồn tại chưa, nếu chưa thì thêm
    IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
    BEGIN
        INSERT INTO Students (StudentID, ClassID, AvatarURL)
        VALUES (@StudentID, @ClassID, '/avatars/default.png');
        PRINT N'Đã thêm ' + @StudentUsername + N' vào lớp ' + @ClassName;
    END
    ELSE
    BEGIN
        PRINT N'Học sinh ' + @StudentUsername + N' đã có lớp rồi!';
    END
END;
GO
-- PHÂN BỔ HỌC SINH VÀO LỚP 5A (Student 1 - 10)
EXEC AddStudentToClass 'student1', N'Lớp 5A';
EXEC AddStudentToClass 'student2', N'Lớp 5A';
EXEC AddStudentToClass 'student3', N'Lớp 5A';
EXEC AddStudentToClass 'student4', N'Lớp 5A';
EXEC AddStudentToClass 'student5', N'Lớp 5A';
EXEC AddStudentToClass 'student6', N'Lớp 5A';
EXEC AddStudentToClass 'student7', N'Lớp 5A';
EXEC AddStudentToClass 'student8', N'Lớp 5A';
EXEC AddStudentToClass 'student9', N'Lớp 5A';
EXEC AddStudentToClass 'student10', N'Lớp 5A';
-- PHÂN BỔ HỌC SINH VÀO LỚP 5B (Student 11 - 20)
EXEC AddStudentToClass 'student11', N'Lớp 5B';
EXEC AddStudentToClass 'student12', N'Lớp 5B';
EXEC AddStudentToClass 'student13', N'Lớp 5B';
EXEC AddStudentToClass 'student14', N'Lớp 5B';
EXEC AddStudentToClass 'student15', N'Lớp 5B';
EXEC AddStudentToClass 'student16', N'Lớp 5B';
EXEC AddStudentToClass 'student17', N'Lớp 5B';
EXEC AddStudentToClass 'student18', N'Lớp 5B';
EXEC AddStudentToClass 'student19', N'Lớp 5B';
EXEC AddStudentToClass 'student20', N'Lớp 5B';
-- PHÂN BỔ HỌC SINH VÀO LỚP 5C (Student 21 - 30)
EXEC AddStudentToClass 'student21', N'Lớp 5C';
EXEC AddStudentToClass 'student22', N'Lớp 5C';
EXEC AddStudentToClass 'student23', N'Lớp 5C';
EXEC AddStudentToClass 'student24', N'Lớp 5C';
EXEC AddStudentToClass 'student25', N'Lớp 5C';
EXEC AddStudentToClass 'student26', N'Lớp 5C';
EXEC AddStudentToClass 'student27', N'Lớp 5C';
EXEC AddStudentToClass 'student28', N'Lớp 5C';
EXEC AddStudentToClass 'student29', N'Lớp 5C';
EXEC AddStudentToClass 'student30', N'Lớp 5C';
-- PHÂN BỔ HỌC SINH VÀO LỚP 5D (Student 31 - 40)
EXEC AddStudentToClass 'student31', N'Lớp 5D';
EXEC AddStudentToClass 'student32', N'Lớp 5D';
EXEC AddStudentToClass 'student33', N'Lớp 5D';
EXEC AddStudentToClass 'student34', N'Lớp 5D';
EXEC AddStudentToClass 'student35', N'Lớp 5D';
EXEC AddStudentToClass 'student36', N'Lớp 5D';
EXEC AddStudentToClass 'student37', N'Lớp 5D';
EXEC AddStudentToClass 'student38', N'Lớp 5D';
EXEC AddStudentToClass 'student39', N'Lớp 5D';
EXEC AddStudentToClass 'student40', N'Lớp 5D';
GO

--Màn 2: Sắp xếp(Scramble)
USE GameHocTiengAnh1;
GO

-- 1. Tạo Topic riêng cho Game Round 2
INSERT INTO Topics (TopicName) VALUES (N'Game Round 2 Pool');
DECLARE @GameTopic2ID INT = SCOPE_IDENTITY(); -- Lấy ID vừa tạo

-- 2. Tạo 1 câu hỏi "Container" chứa danh sách các câu cần sắp xếp
-- QuestionType vẫn là 'scramble' (sắp xếp)
INSERT INTO Questions (TopicID, QuestionText, QuestionType, HintText, CorrectAnswer)
VALUES (@GameTopic2ID, N'Sắp xếp các từ xáo trộn thành câu hoàn chỉnh', 'scramble', N'Game Round 2', N'All Sentences');

DECLARE @Q2_ID INT = SCOPE_IDENTITY();



-- ====================================================
-- BƯỚC 1: XÓA INDEX CŨ (Khắc phục lỗi Msg 1913)
-- ====================================================
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Leaderboard_Sort' AND object_id = OBJECT_ID('LeaderboardEntries'))
BEGIN
    DROP INDEX IX_Leaderboard_Sort ON LeaderboardEntries;
    PRINT N'✅ Đã xóa Index cũ thành công.';
END
GO

-- ====================================================
-- BƯỚC 2: GỠ BỎ RÀNG BUỘC CỦA CỘT TOTALSTARS (Khắc phục lỗi Msg 5074)
-- ====================================================
DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = name 
FROM sys.default_constraints 
WHERE parent_object_id = OBJECT_ID('LeaderboardEntries') 
AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('LeaderboardEntries') AND name = 'TotalStars');

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE LeaderboardEntries DROP CONSTRAINT ' + @ConstraintName);
    PRINT N'✅ Đã gỡ bỏ khóa (Constraint): ' + @ConstraintName;
END
GO

-- ====================================================
-- BƯỚC 3: XÓA CỘT TOTALSTARS (Khắc phục lỗi Msg 4922)
-- ====================================================
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'LeaderboardEntries') AND name = 'TotalStars')
BEGIN
    ALTER TABLE LeaderboardEntries DROP COLUMN TotalStars;
    PRINT N'✅ Đã xóa cột TotalStars thành công.';
END
GO

-- ====================================================
-- BƯỚC 4: TẠO LẠI INDEX MỚI (CHUẨN ĐIỂM + THỜI GIAN)
-- ====================================================
CREATE INDEX IX_Leaderboard_Sort 
ON LeaderboardEntries(ClassID, RankMonth, TotalScore DESC, TotalTime ASC);
GO
USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU QUÁ TRÌNH DỌN DẸP DỮ LIỆU CŨ (GLOBAL SUCCESS) ===';

-- 1. XÓA DỮ LIỆU LIÊN QUAN ĐẾN HOẠT ĐỘNG CỦA HỌC SINH (Bắt buộc vì dính khóa ngoại tới Câu hỏi & Game)
-- Nếu không xóa bảng này, bạn không thể xóa Câu hỏi hay Game được.
DELETE FROM StudentAnswers;
PRINT N'✅ Đã xóa chi tiết câu trả lời của học sinh (StudentAnswers).';

DELETE FROM PlayHistory;
PRINT N'✅ Đã xóa lịch sử chơi game (PlayHistory) để làm sạch dữ liệu cũ.';

-- (Tùy chọn) Xóa bảng xếp hạng để tính lại từ đầu cho sách mới
DELETE FROM LeaderboardEntries;
PRINT N'✅ Đã reset bảng xếp hạng (LeaderboardEntries).';


-- 2. XÓA NHÓM CÂU HỎI VÀ GAME (Cấp con)
DELETE FROM QuestionOptions;
PRINT N'✅ Đã xóa các lựa chọn đáp án (QuestionOptions).';

DELETE FROM Game_Questions;
PRINT N'✅ Đã xóa liên kết Game - Câu hỏi (Game_Questions).';

DELETE FROM Questions;
PRINT N'✅ Đã xóa toàn bộ câu hỏi cũ (Questions).';


-- 3. Xóa NHÓM KIẾN THỨC (Cấp trung gian)
DELETE FROM Vocabulary;
PRINT N'✅ Đã xóa toàn bộ từ vựng cũ (Vocabulary).';

DELETE FROM Grammar;
PRINT N'✅ Đã xóa toàn bộ ngữ pháp cũ (Grammar).';

DELETE FROM Games;
PRINT N'✅ Đã xóa các màn chơi cũ (Games).';


-- 4. XÓA CHỦ ĐỀ (Cấp cha - Root)
DELETE FROM Topics;
PRINT N'✅ Đã xóa toàn bộ chủ đề cũ (Topics).';


-- 5. RESET LẠI BỘ ĐẾM ID (Để dữ liệu Cánh Diều mới bắt đầu từ ID 1 cho đẹp)
DBCC CHECKIDENT ('Topics', RESEED, 0);
DBCC CHECKIDENT ('Vocabulary', RESEED, 0);
DBCC CHECKIDENT ('Grammar', RESEED, 0);
DBCC CHECKIDENT ('Questions', RESEED, 0);
DBCC CHECKIDENT ('QuestionOptions', RESEED, 0);
DBCC CHECKIDENT ('Games', RESEED, 0);
DBCC CHECKIDENT ('PlayHistory', RESEED, 0);
PRINT N'✅ Đã reset bộ đếm ID (Identity) về 0.';

PRINT N'=== HOÀN TẤT DỌN DẸP. DATABASE ĐÃ SẴN SÀNG CHO SÁCH CÁNH DIỀU ===';
GO
USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU QUÁ TRÌNH NẠP DỮ LIỆU SÁCH CÁNH DIỀU (EXPLORE OUR WORLD) ===';

-- ==========================================================
-- BƯỚC 1: DỌN DẸP DỮ LIỆU CŨ (RESET)
-- ==========================================================
-- Xóa bảng con trước để tránh lỗi khóa ngoại
DELETE FROM StudentAnswers;
DELETE FROM PlayHistory;
DELETE FROM LeaderboardEntries;
DELETE FROM QuestionOptions;
DELETE FROM Game_Questions;
DELETE FROM Questions;

-- Xóa nội dung kiến thức
DELETE FROM Vocabulary;
DELETE FROM Grammar;
DELETE FROM Games;
DELETE FROM Topics;

-- Reset bộ đếm ID về 0 để dữ liệu đẹp
DBCC CHECKIDENT ('Topics', RESEED, 0);
DBCC CHECKIDENT ('Vocabulary', RESEED, 0);
DBCC CHECKIDENT ('Grammar', RESEED, 0);
GO

-- ==========================================================
-- BƯỚC 2: TẠO KHUNG CHỦ ĐỀ CHO CẢ 9 UNIT (0 - 8)
-- ==========================================================
INSERT INTO Topics (TopicName) VALUES 
    (N'Unit 0: Getting Started'),       -- Dựa trên ảnh cũ
    (N'Unit 1: Animal Habitats'),       -- Dựa trên ảnh cũ
    (N'Unit 2: Let''s Eat!'),           -- Dựa trên ảnh cũ
    -- Các Unit dưới đây là TÊN DỰ KIẾN (cần ảnh để xác nhận chính xác tên tiếng Anh)
    (N'Unit 3: (Chờ cập nhật tên...)'), 
    (N'Unit 4: (Chờ cập nhật tên...)'),
    (N'Unit 5: (Chờ cập nhật tên...)'),
    (N'Unit 6: (Chờ cập nhật tên...)'),
    (N'Unit 7: (Chờ cập nhật tên...)'),
    (N'Unit 8: (Chờ cập nhật tên...)');
GO

-- KHAI BÁO BIẾN ID ĐỂ DÙNG CHO CÁC BƯỚC SAU
DECLARE @Unit0ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 0%');
DECLARE @Unit1ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 1%');
DECLARE @Unit2ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 2%');

-- ==========================================================
-- BƯỚC 3: NẠP TỪ VỰNG & NGỮ PHÁP CHI TIẾT (UNIT 0, 1, 2)
-- ==========================================================

PRINT N'--- Đang nạp dữ liệu Unit 0: Getting Started ---';

-- 1. Weather (Thời tiết)
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID) VALUES 
    ('cloudy', N'nhiều mây', 'Adjective', N'It''s cloudy.', @Unit0ID),
    ('cold', N'lạnh', 'Adjective', N'It''s cold.', @Unit0ID),
    ('cool', N'mát mẻ', 'Adjective', N'It''s cool.', @Unit0ID),
    ('hot', N'nóng', 'Adjective', N'It''s hot.', @Unit0ID),
    ('rainy', N'có mưa', 'Adjective', N'It''s rainy.', @Unit0ID),
    ('snowy', N'có tuyết', 'Adjective', N'It''s snowy.', @Unit0ID),
    ('sunny', N'có nắng', 'Adjective', N'It''s sunny.', @Unit0ID),
    ('warm', N'ấm áp', 'Adjective', N'It''s warm.', @Unit0ID);

-- 2. Seasons (Mùa)
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID) VALUES 
    ('fall', N'mùa thu', 'Noun', N'I like fall.', @Unit0ID),
    ('spring', N'mùa xuân', 'Noun', N'Flowers bloom in spring.', @Unit0ID),
    ('summer', N'mùa hè', 'Noun', N'It is hot in summer.', @Unit0ID),
    ('winter', N'mùa đông', 'Noun', N'It is cold in winter.', @Unit0ID),
    ('the dry season', N'mùa khô', 'Noun', N'It is the dry season.', @Unit0ID),
    ('the rainy season', N'mùa mưa', 'Noun', N'It rains a lot in the rainy season.', @Unit0ID);

-- 3. Months (Tháng) - Nhập đủ 12 tháng theo sách liệt kê
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('January', N'Tháng 1', 'Noun', @Unit0ID), ('February', N'Tháng 2', 'Noun', @Unit0ID),
    ('March', N'Tháng 3', 'Noun', @Unit0ID), ('April', N'Tháng 4', 'Noun', @Unit0ID),
    ('May', N'Tháng 5', 'Noun', @Unit0ID), ('June', N'Tháng 6', 'Noun', @Unit0ID),
    ('July', N'Tháng 7', 'Noun', @Unit0ID), ('August', N'Tháng 8', 'Noun', @Unit0ID),
    ('September', N'Tháng 9', 'Noun', @Unit0ID), ('October', N'Tháng 10', 'Noun', @Unit0ID),
    ('November', N'Tháng 11', 'Noun', @Unit0ID), ('December', N'Tháng 12', 'Noun', @Unit0ID);

-- 4. Numbers and Math
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID) VALUES 
    ('twenty to one thousand', N'số 20 đến 1000', 'Number', N'Count from twenty to one thousand.', @Unit0ID),
    ('plus', N'cộng (+)', 'Preposition', N'Two plus two.', @Unit0ID),
    ('minus', N'trừ (-)', 'Preposition', N'Five minus three.', @Unit0ID),
    ('equals', N'bằng (=)', 'Verb', N'One plus one equals two.', @Unit0ID);

-- GRAMMAR UNIT 0
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi về thời tiết', N'What''s the weather like in [Place]?', N'Hỏi thời tiết tại một nơi.', N'What''s the weather like in Ha Noi? It''s hot.', @Unit0ID),
    (N'Hỏi về mùa yêu thích', N'What''s your favorite season?', N'Hỏi sở thích về mùa.', N'I like summer.', @Unit0ID),
    (N'Câu hỏi Yes/No về sở thích', N'Do you like [Season]?', N'Hỏi xem có thích mùa đó không.', N'Do you like the rainy season? Yes, I do.', @Unit0ID),
    (N'Hỏi về tháng sinh nhật', N'Is your birthday in [Month/Season]?', N'Xác nhận thời điểm sinh nhật.', N'Is your birthday in June? Yes, it is.', @Unit0ID),
    (N'Phép toán', N'[Number] plus [Number] equals...?', N'Thực hiện phép cộng.', N'Twenty plus five equals... twenty-five.', @Unit0ID);


PRINT N'--- Đang nạp dữ liệu Unit 1: Animal Habitats ---';

-- VOCABULARY UNIT 1 (Theo cột Vocabulary trong ảnh)
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('a beak', N'cái mỏ', 'Noun', @Unit1ID),
    ('a cave', N'hang động', 'Noun', @Unit1ID),
    ('a desert', N'sa mạc', 'Noun', @Unit1ID),
    ('a forest', N'khu rừng', 'Noun', @Unit1ID),
    ('a hive', N'tổ ong', 'Noun', @Unit1ID),
    ('a nest', N'tổ chim', 'Noun', @Unit1ID),
    ('a pouch', N'túi (của thú có túi)', 'Noun', @Unit1ID),
    ('a tongue', N'cái lưỡi', 'Noun', @Unit1ID),
    ('an island', N'hòn đảo', 'Noun', @Unit1ID),
    ('catch', N'bắt, chụp', 'Verb', @Unit1ID),
    ('claws', N'móng vuốt', 'Noun', @Unit1ID),
    ('fight', N'chiến đấu', 'Verb', @Unit1ID),
    ('fur', N'bộ lông thú', 'Noun', @Unit1ID),
    ('horns', N'cái sừng', 'Noun', @Unit1ID),
    ('ice', N'băng', 'Noun', @Unit1ID),
    ('mud', N'bùn', 'Noun', @Unit1ID);

-- GRAMMAR UNIT 1
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Câu hỏi lựa chọn nơi ở', N'Do [Animals] live in [Place A] or [Place B]?', N'Hỏi xác nhận nơi sống của động vật.', N'Do bees live in hives or nests? They live in hives.', @Unit1ID),
    (N'Sử dụng bộ phận cơ thể (Use... to)', N'[Animals] use their [Body Part] to [Action].', N'Mô tả chức năng bộ phận cơ thể.', N'Giraffes use their long tongues to clean their ears. Goats use their horns to fight.', @Unit1ID);


PRINT N'--- Đang nạp dữ liệu Unit 2: Let''s Eat ---';

-- VOCABULARY UNIT 2 (Theo cột Vocabulary trong ảnh)
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('a bottle of oil', N'một chai dầu', 'Phrase', @Unit2ID),
    ('a bowl of sugar', N'một bát đường', 'Phrase', @Unit2ID),
    ('a box of cereal', N'một hộp ngũ cốc', 'Phrase', @Unit2ID),
    ('a can of soda', N'một lon nước ngọt', 'Phrase', @Unit2ID),
    ('a glass of juice', N'một ly nước ép', 'Phrase', @Unit2ID),
    ('a jar of olives', N'một lọ ô liu', 'Phrase', @Unit2ID),
    ('a loaf of bread', N'một ổ bánh mì', 'Phrase', @Unit2ID),
    ('a piece of cake', N'một miếng bánh', 'Phrase', @Unit2ID),
    ('beans', N'đậu', 'Noun', @Unit2ID),
    ('chips', N'khoai tây chiên', 'Noun', @Unit2ID),
    ('chocolate', N'sô cô la', 'Noun', @Unit2ID),
    ('ice cream', N'kem', 'Noun', @Unit2ID),
    ('meat', N'thịt', 'Noun', @Unit2ID),
    ('noodles', N'mì', 'Noun', @Unit2ID),
    ('rice', N'cơm/gạo', 'Noun', @Unit2ID),
    ('yogurt', N'sữa chua', 'Noun', @Unit2ID);

-- GRAMMAR UNIT 2
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Lời mời/Yêu cầu lịch sự', N'May I have some [Food], please? / Would you like some [Food]?', N'Xin hoặc mời đồ ăn.', N'May I have some chips, please? Not right now. Dinner is at 7:00. / Would you like some ice cream? Yes, please.', @Unit2ID),
    (N'Hỏi số lượng (Countable)', N'Are there any [Plural Noun] in the [Container]?', N'Hỏi về thức ăn đếm được.', N'Are there any olives in the jar? Yes, there are a few olives. / Are there any sandwiches in the box? Yes, there are many sandwiches.', @Unit2ID),
    (N'Hỏi số lượng (Uncountable)', N'Is there any [Mass Noun] in the [Container]?', N'Hỏi về thức ăn không đếm được.', N'Is there any soda in the bottle? Yes, there''s a little soda. / Is there a lot of juice in the glass? No, there isn''t much.', @Unit2ID);

PRINT N'=== ĐÃ NẠP XONG UNIT 0, 1, 2 ===';
PRINT N'=== VUI LÒNG CUNG CẤP ẢNH MỤC LỤC CỦA UNIT 3 ĐẾN 8 ĐỂ TIẾP TỤC ===';
GO

USE GameHocTiengAnh1;
GO

PRINT N'=== TIẾP TỤC CẬP NHẬT UNIT 3 ĐẾN UNIT 8 (THEO ẢNH MỚI) ===';

-- ==========================================================
-- BƯỚC 1: CẬP NHẬT TÊN CHÍNH XÁC CHO CÁC TOPIC (UNIT 3-8)
-- ==========================================================
UPDATE Topics SET TopicName = N'Unit 3: On the Move!' WHERE TopicName LIKE N'Unit 3%';
UPDATE Topics SET TopicName = N'Unit 4: Our Senses' WHERE TopicName LIKE N'Unit 4%';
UPDATE Topics SET TopicName = N'Unit 5: Our Health' WHERE TopicName LIKE N'Unit 5%';
UPDATE Topics SET TopicName = N'Unit 6: The World of School' WHERE TopicName LIKE N'Unit 6%';
UPDATE Topics SET TopicName = N'Unit 7: The World of Work' WHERE TopicName LIKE N'Unit 7%';
UPDATE Topics SET TopicName = N'Unit 8: Fantastic Holidays and Festivals' WHERE TopicName LIKE N'Unit 8%';
GO

-- KHAI BÁO BIẾN ID ĐỂ DÙNG (Lấy lại ID đã tạo ở bước trước)
DECLARE @Unit3ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 3%');
DECLARE @Unit4ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 4%');
DECLARE @Unit5ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 5%');
DECLARE @Unit6ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 6%');
DECLARE @Unit7ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 7%');
DECLARE @Unit8ID INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 8%');

-- ==========================================================
-- UNIT 3: ON THE MOVE! (Phương tiện & Di chuyển)
-- ==========================================================
PRINT N'--- Đang nạp Unit 3 ---';
-- Vocabulary
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('a boat', N'cái thuyền', 'Noun', @Unit3ID),
    ('a bus', N'xe buýt', 'Noun', @Unit3ID),
    ('a helicopter', N'máy bay trực thăng', 'Noun', @Unit3ID),
    ('a kick scooter', N'xe trượt', 'Noun', @Unit3ID),
    ('a motorcycle', N'xe máy', 'Noun', @Unit3ID),
    ('an airplane', N'máy bay', 'Noun', @Unit3ID),
    ('cycle', N'đạp xe', 'Verb', @Unit3ID),
    ('drive', N'lái xe (ô tô)', 'Verb', @Unit3ID),
    ('fly', N'bay / lái máy bay', 'Verb', @Unit3ID),
    ('get off', N'xuống xe', 'Verb', @Unit3ID),
    ('get on', N'lên xe', 'Verb', @Unit3ID),
    ('on foot', N'đi bộ', 'Phrase', @Unit3ID),
    ('park', N'đỗ xe', 'Verb', @Unit3ID),
    ('ride', N'lái xe (2 bánh)/cưỡi', 'Verb', @Unit3ID),
    ('row', N'chèo thuyền', 'Verb', @Unit3ID),
    ('the subway', N'tàu điện ngầm', 'Noun', @Unit3ID);

-- Grammar (Hiện tại đơn & Trạng từ tần suất)
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi về phương tiện đi lại', 
     N'Q: Do you go to school by [Vehicle]?
A: No, I don''t. I go to school [by Vehicle / on foot].', 
     N'Hỏi cách di chuyển đến trường.', 
     N'Do you go to school by bus? No, I don''t. I go to school on foot.', @Unit3ID),
    
    (N'Hỏi tần suất (How often)', 
     N'Q: Do you often [Action]?
A: Yes, I do. / No, I never [Action].
Q: How often do you [Action]?
A: I [Action] twice a week.', 
     N'Hỏi mức độ thường xuyên của hành động.', 
     N'Do you often ride your kick scooter? No, I never ride my kick scooter.', @Unit3ID);


-- ==========================================================
-- UNIT 4: OUR SENSES (Các giác quan)
-- ==========================================================
PRINT N'--- Đang nạp Unit 4 ---';
-- Vocabulary
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('beautiful', N'đẹp', 'Adjective', @Unit4ID),
    ('bitter', N'đắng', 'Adjective', @Unit4ID),
    ('burnt', N'bị cháy/khét', 'Adjective', @Unit4ID),
    ('fatty', N'béo ngậy', 'Adjective', @Unit4ID),
    ('hard', N'cứng', 'Adjective', @Unit4ID),
    ('juicy', N'mọng nước', 'Adjective', @Unit4ID),
    ('loud', N'ồn ào/to', 'Adjective', @Unit4ID),
    ('quiet', N'yên tĩnh', 'Adjective', @Unit4ID),
    ('salty', N'mặn', 'Adjective', @Unit4ID),
    ('smell', N'ngửi/có mùi', 'Verb', @Unit4ID),
    ('soft', N'mềm', 'Adjective', @Unit4ID),
    ('sour', N'chua', 'Adjective', @Unit4ID),
    ('spicy', N'cay', 'Adjective', @Unit4ID),
    ('sweet', N'ngọt', 'Adjective', @Unit4ID),
    ('taste', N'nếm/có vị', 'Verb', @Unit4ID),
    ('ugly', N'xấu xí', 'Adjective', @Unit4ID);

-- Grammar (Quá khứ đơn với giác quan)
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi về trải nghiệm giác quan (Quá khứ)', 
     N'Q: Did you [smell/hear/touch/see] the [Object]?
A: Yes, I did. It [smelled/sounded/felt/looked] [Adjective].
A: No, I didn''t.', 
     N'Hỏi về cảm nhận trong quá khứ.', 
     N'Did you smell the soup? Yes, I smelled it. It was great. / Did you hear the music? Yes, It sounded loud.', @Unit4ID);


-- ==========================================================
-- UNIT 5: OUR HEALTH (Sức khỏe)
-- ==========================================================
PRINT N'--- Đang nạp Unit 5 ---';
-- Vocabulary
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('a cold', N'cảm lạnh', 'Noun', @Unit5ID),
    ('a cough', N'ho', 'Noun', @Unit5ID),
    ('a fever', N'sốt', 'Noun', @Unit5ID),
    ('a headache', N'đau đầu', 'Noun', @Unit5ID),
    ('a rash', N'phát ban', 'Noun', @Unit5ID),
    ('a sore throat', N'đau họng', 'Noun', @Unit5ID),
    ('a stomachache', N'đau bụng', 'Noun', @Unit5ID),
    ('a toothache', N'đau răng', 'Noun', @Unit5ID),
    ('drink ginger tea', N'uống trà gừng', 'Phrase', @Unit5ID),
    ('get some rest', N'nghỉ ngơi chút', 'Phrase', @Unit5ID),
    ('keep your hands clean', N'giữ tay sạch sẽ', 'Phrase', @Unit5ID),
    ('rest your eyes', N'để mắt nghỉ ngơi', 'Phrase', @Unit5ID),
    ('runny nose', N'sổ mũi', 'Noun', @Unit5ID),
    ('see a dentist', N'gặp nha sĩ', 'Phrase', @Unit5ID),
    ('sore eyes', N'đau mắt', 'Noun', @Unit5ID),
    ('take some medicine', N'uống thuốc', 'Phrase', @Unit5ID);

-- Grammar (Lời khuyên Should/Shouldn't & Quá khứ đơn phủ định)
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi bệnh & Lời khuyên (Should)', 
     N'Q: What''s the matter?
A: I have a [Illness]. Should I [Action]?
B: Yes, you should. / No, you shouldn''t.', 
     N'Hỏi thăm sức khỏe và xin lời khuyên.', 
     N'I have a toothache. Should I take some medicine? No, you shouldn''t. You should see a dentist.', @Unit5ID),
    
    (N'Kể về bệnh trong quá khứ', 
     N'I didn''t feel well [Time].
I had a [Illness].
I [Action - Past Tense].', 
     N'Mô tả tình trạng ốm đau đã qua.', 
     N'I didn''t feel well yesterday. I had a sore throat. I drank ginger tea.', @Unit5ID);


-- ==========================================================
-- UNIT 6: THE WORLD OF SCHOOL (Trường học)
-- ==========================================================
PRINT N'--- Đang nạp Unit 6 ---';
-- Vocabulary
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('art', N'mỹ thuật', 'Noun', @Unit6ID),
    ('computer science', N'tin học', 'Noun', @Unit6ID),
    ('do volunteer work', N'làm tình nguyện', 'Phrase', @Unit6ID),
    ('go on a field trip', N'đi dã ngoại thực tế', 'Phrase', @Unit6ID),
    ('history', N'lịch sử', 'Noun', @Unit6ID),
    ('join a club', N'tham gia câu lạc bộ', 'Phrase', @Unit6ID),
    ('literature', N'ngữ văn', 'Noun', @Unit6ID),
    ('make a poster', N'làm áp phích', 'Phrase', @Unit6ID),
    ('make a video', N'làm video', 'Phrase', @Unit6ID),
    ('math', N'toán', 'Noun', @Unit6ID),
    ('music', N'âm nhạc', 'Noun', @Unit6ID),
    ('physical education', N'thể dục (PE)', 'Noun', @Unit6ID),
    ('play board games', N'chơi trò chơi bàn cờ', 'Phrase', @Unit6ID),
    ('play sports', N'chơi thể thao', 'Phrase', @Unit6ID),
    ('read books', N'đọc sách', 'Phrase', @Unit6ID),
    ('science', N'khoa học', 'Noun', @Unit6ID);

-- Grammar (Quá khứ đơn với Wh-Questions)
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi về thời khóa biểu quá khứ', 
     N'Q: What classes did you have [Time]?
A: I had [Subject 1], [Subject 2]...
Q: When did you have [Subject]?
A: I had [Subject] on [Day].', 
     N'Hỏi về môn học đã học.', 
     N'What classes did you have last week? I had math and music. When did you have math? I had math on Tuesday.', @Unit6ID),
    
    (N'Hỏi về chuyến đi quá khứ (Where/Why)', 
     N'Q: Where did you go [Time]?
A: I went to [Place].
Q: Why did you go to the [Place]?
A: We went there to [Purpose].', 
     N'Hỏi địa điểm và lý do đi đâu đó.', 
     N'Where did you go last summer? I went to a zoo. Why? We went there to learn about animals.', @Unit6ID);


-- ==========================================================
-- UNIT 7: THE WORLD OF WORK (Nghề nghiệp)
-- ==========================================================
PRINT N'--- Đang nạp Unit 7 ---';
-- Vocabulary
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('a babysitter', N'người trông trẻ', 'Noun', @Unit7ID),
    ('a builder', N'thợ xây', 'Noun', @Unit7ID),
    ('a dentist', N'nha sĩ', 'Noun', @Unit7ID),
    ('a flight attendant', N'tiếp viên hàng không', 'Noun', @Unit7ID),
    ('a magician', N'ảo thuật gia', 'Noun', @Unit7ID),
    ('a mechanic', N'thợ cơ khí', 'Noun', @Unit7ID),
    ('a musician', N'nhạc sĩ', 'Noun', @Unit7ID),
    ('a salesperson', N'nhân viên bán hàng', 'Noun', @Unit7ID),
    ('a tailor', N'thợ may', 'Noun', @Unit7ID),
    ('an athlete', N'vận động viên', 'Noun', @Unit7ID),
    ('build', N'xây dựng', 'Verb', @Unit7ID),
    ('look after', N'chăm sóc', 'Verb', @Unit7ID),
    ('perform', N'biểu diễn', 'Verb', @Unit7ID),
    ('repair', N'sửa chữa', 'Verb', @Unit7ID),
    ('sell', N'bán', 'Verb', @Unit7ID),
    ('serve', N'phục vụ', 'Verb', @Unit7ID);

-- Grammar (Mơ ước nghề nghiệp & Trạng từ chỉ cách thức)
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi về nghề nghiệp tương lai', 
     N'Q: What do you want to be one day?
A: I want to be a [Job]. I will [Activity].', 
     N'Hỏi ước mơ và dự định.', 
     N'I want to be a salesperson. I will sell delicious foods.', @Unit7ID),
    
    (N'Lý do thích ai đó (Adverbs of Manner)', 
     N'Q: Why do you like this [Job/Person]?
A: He/She [Verbs] [Adverb].', 
     N'Giải thích lý do thích dựa trên cách họ làm việc.', 
     N'Why do you like this athlete? He runs fast. She sings beautifully.', @Unit7ID);


-- ==========================================================
-- UNIT 8: FANTASTIC HOLIDAYS AND FESTIVALS (Lễ hội)
-- ==========================================================
PRINT N'--- Đang nạp Unit 8 ---';
-- Vocabulary
INSERT INTO Vocabulary (Word, Meaning, WordType, TopicID) VALUES 
    ('a campsite', N'địa điểm cắm trại', 'Noun', @Unit8ID),
    ('a costume', N'trang phục hóa trang', 'Noun', @Unit8ID),
    ('a history museum', N'bảo tàng lịch sử', 'Noun', @Unit8ID),
    ('a lantern', N'đèn lồng', 'Noun', @Unit8ID),
    ('a lion dance', N'múa lân', 'Noun', @Unit8ID),
    ('a resort', N'khu nghỉ dưỡng', 'Noun', @Unit8ID),
    ('a shopping mall', N'trung tâm mua sắm', 'Noun', @Unit8ID),
    ('a souvenir shop', N'cửa hàng lưu niệm', 'Noun', @Unit8ID),
    ('a street market', N'chợ đường phố', 'Noun', @Unit8ID),
    ('a theme park', N'công viên giải trí', 'Noun', @Unit8ID),
    ('a waterfall', N'thác nước', 'Noun', @Unit8ID),
    ('Christmas', N'Giáng sinh', 'Noun', @Unit8ID),
    ('Halloween', N'Lễ hội hóa lộ quỷ', 'Noun', @Unit8ID),
    ('lucky money', N'tiền lì xì', 'Noun', @Unit8ID),
    ('Lunar New Year', N'Tết Nguyên Đán', 'Noun', @Unit8ID),
    ('Mid-Autumn Festival', N'Tết Trung Thu', 'Noun', @Unit8ID);

-- Grammar (Chỉ đường & Tương lai đơn với Will)
INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi đường (Directions)', 
     N'Q: Could you show me the way to the [Place]?
A: Sure. Go straight and then turn [left/right]. It''s on your [left/right].', 
     N'Hỏi và chỉ dẫn đường đi.', 
     N'Could you show me the way to the souvenir shop? Turn left on Main Street.', @Unit8ID),
    
    (N'Kế hoạch lễ hội (Will/Won''t)', 
     N'The [Festival] is [Time].
I will [Action]. / I won''t [Action].
Q: What will you do there?
A: I''ll [Action].', 
     N'Nói về dự định trong tương lai gần.', 
     N'The Mid-Autumn Festival is next week. I''ll light lanterns.', @Unit8ID);

PRINT N'✅ ĐÃ HOÀN TẤT CẬP NHẬT TOÀN BỘ 9 UNIT (0-8) CHO SÁCH CÁNH DIỀU!';
GO

USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO 20 CẶP CÂU HỎI (VOCAB + GRAMMAR) CHO MỖI UNIT ===';

-- 1. DỌN DẸP DỮ LIỆU GAME CŨ (Chỉ xóa loại matching)
DELETE FROM QuestionOptions WHERE QuestionID IN (SELECT QuestionID FROM Questions WHERE QuestionType = 'matching');
DELETE FROM Questions WHERE QuestionType = 'matching';
PRINT N'🧹 Đã dọn dẹp dữ liệu cũ.';

-- Khai báo biến
DECLARE @Q_ID INT;
DECLARE @U0 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 0%');
DECLARE @U1 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 1%');
DECLARE @U2 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 2%');
DECLARE @U3 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 3%');
DECLARE @U4 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 4%');
DECLARE @U5 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 5%');
DECLARE @U6 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 6%');
DECLARE @U7 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 7%');
DECLARE @U8 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 8%');

-- ==========================================================
-- UNIT 0: GETTING STARTED (20 PAIRS)
-- ==========================================================
IF @U0 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U0, N'Nối từ và câu Unit 0', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Sunny", "R": "Có nắng"}', 1),
    (@Q_ID, N'{"L": "Cloudy", "R": "Có mây"}', 1),
    (@Q_ID, N'{"L": "Rainy", "R": "Có mưa"}', 1),
    (@Q_ID, N'{"L": "Snowy", "R": "Có tuyết"}', 1),
    (@Q_ID, N'{"L": "Spring", "R": "Mùa xuân"}', 1),
    (@Q_ID, N'{"L": "Summer", "R": "Mùa hè"}', 1),
    (@Q_ID, N'{"L": "Fall", "R": "Mùa thu"}', 1),
    (@Q_ID, N'{"L": "Winter", "R": "Mùa đông"}', 1),
    (@Q_ID, N'{"L": "January", "R": "Tháng 1"}', 1),
    (@Q_ID, N'{"L": "December", "R": "Tháng 12"}', 1),
    (@Q_ID, N'{"L": "Plus (+)", "R": "Cộng"}', 1),
    (@Q_ID, N'{"L": "Minus (-)", "R": "Trừ"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "What is the weather like?", "R": "It is hot and sunny."}', 1),
    (@Q_ID, N'{"L": "Do you like winter?", "R": "No, I do not. It is cold."}', 1),
    (@Q_ID, N'{"L": "What is your favorite season?", "R": "I like summer."}', 1),
    (@Q_ID, N'{"L": "Is your birthday in June?", "R": "Yes, it is."}', 1),
    (@Q_ID, N'{"L": "Ten plus five", "R": "equals fifteen."}', 1),
    (@Q_ID, N'{"L": "Twenty minus ten", "R": "equals ten."}', 1),
    (@Q_ID, N'{"L": "The dry season", "R": "is very hot."}', 1),
    (@Q_ID, N'{"L": "The rainy season", "R": "has a lot of rain."}', 1);
END

-- ==========================================================
-- UNIT 1: ANIMAL HABITATS (20 PAIRS)
-- ==========================================================
IF @U1 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U1, N'Nối từ và câu Unit 1', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Cave", "R": "Hang động"}', 1),
    (@Q_ID, N'{"L": "Desert", "R": "Sa mạc"}', 1),
    (@Q_ID, N'{"L": "Forest", "R": "Rừng"}', 1),
    (@Q_ID, N'{"L": "Island", "R": "Hòn đảo"}', 1),
    (@Q_ID, N'{"L": "Beak", "R": "Mỏ chim"}', 1),
    (@Q_ID, N'{"L": "Claws", "R": "Móng vuốt"}', 1),
    (@Q_ID, N'{"L": "Fur", "R": "Bộ lông thú"}', 1),
    (@Q_ID, N'{"L": "Horns", "R": "Cái sừng"}', 1),
    (@Q_ID, N'{"L": "Pouch", "R": "Túi (Chuột túi)"}', 1),
    (@Q_ID, N'{"L": "Hive", "R": "Tổ ong"}', 1),
    (@Q_ID, N'{"L": "Nest", "R": "Tổ chim"}', 1),
    (@Q_ID, N'{"L": "Mud", "R": "Bùn đất"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "Where do bees live?", "R": "They live in hives."}', 1),
    (@Q_ID, N'{"L": "Do birds live in caves?", "R": "No, they live in nests."}', 1),
    (@Q_ID, N'{"L": "Goats use their horns", "R": "to fight."}', 1),
    (@Q_ID, N'{"L": "Birds use their beaks", "R": "to catch food."}', 1),
    (@Q_ID, N'{"L": "Giraffes use their tongues", "R": "to clean their ears."}', 1),
    (@Q_ID, N'{"L": "Cats use their claws", "R": "to climb trees."}', 1),
    (@Q_ID, N'{"L": "Camels live", "R": "in the desert."}', 1),
    (@Q_ID, N'{"L": "Penguins live", "R": "on the ice."}', 1);
END

-- ==========================================================
-- UNIT 2: LET'S EAT! (20 PAIRS)
-- ==========================================================
IF @U2 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U2, N'Nối từ và câu Unit 2', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Spicy", "R": "Cay"}', 1),
    (@Q_ID, N'{"L": "Sour", "R": "Chua"}', 1),
    (@Q_ID, N'{"L": "Bitter", "R": "Đắng"}', 1),
    (@Q_ID, N'{"L": "Sweet", "R": "Ngọt"}', 1),
    (@Q_ID, N'{"L": "Salty", "R": "Mặn"}', 1),
    (@Q_ID, N'{"L": "Cereal", "R": "Ngũ cốc"}', 1),
    (@Q_ID, N'{"L": "Noodles", "R": "Mì"}', 1),
    (@Q_ID, N'{"L": "A bottle", "R": "Một cái chai"}', 1),
    (@Q_ID, N'{"L": "A bowl", "R": "Một cái bát"}', 1),
    (@Q_ID, N'{"L": "A can", "R": "Một cái lon"}', 1),
    (@Q_ID, N'{"L": "A jar", "R": "Một cái lọ"}', 1),
    (@Q_ID, N'{"L": "A loaf", "R": "Một ổ (bánh mì)"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "May I have some chips?", "R": "Yes, please."}', 1),
    (@Q_ID, N'{"L": "Would you like some pizza?", "R": "No, thanks. I am full."}', 1),
    (@Q_ID, N'{"L": "A bowl of", "R": "sugar."}', 1),
    (@Q_ID, N'{"L": "A bottle of", "R": "oil."}', 1),
    (@Q_ID, N'{"L": "Are there any olives?", "R": "Yes, there are a few."}', 1),
    (@Q_ID, N'{"L": "Is there any soda?", "R": "No, there isn''t much."}', 1),
    (@Q_ID, N'{"L": "Lemons taste", "R": "sour."}', 1),
    (@Q_ID, N'{"L": "Chili peppers are", "R": "spicy."}', 1);
END

-- ==========================================================
-- UNIT 3: ON THE MOVE! (20 PAIRS)
-- ==========================================================
IF @U3 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U3, N'Nối từ và câu Unit 3', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Helicopter", "R": "Trực thăng"}', 1),
    (@Q_ID, N'{"L": "Subway", "R": "Tàu điện ngầm"}', 1),
    (@Q_ID, N'{"L": "Airplane", "R": "Máy bay"}', 1),
    (@Q_ID, N'{"L": "Scooter", "R": "Xe trượt/Xe tay ga"}', 1),
    (@Q_ID, N'{"L": "Motorcycle", "R": "Xe máy"}', 1),
    (@Q_ID, N'{"L": "Ferry", "R": "Phà"}', 1),
    (@Q_ID, N'{"L": "On foot", "R": "Đi bộ"}', 1),
    (@Q_ID, N'{"L": "Drive", "R": "Lái xe (ô tô)"}', 1),
    (@Q_ID, N'{"L": "Ride", "R": "Lái/Cưỡi (xe 2 bánh)"}', 1),
    (@Q_ID, N'{"L": "Fly", "R": "Bay"}', 1),
    (@Q_ID, N'{"L": "Get on", "R": "Lên xe"}', 1),
    (@Q_ID, N'{"L": "Get off", "R": "Xuống xe"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "How do you go to school?", "R": "I go by bus."}', 1),
    (@Q_ID, N'{"L": "Do you go by car?", "R": "No, I go on foot."}', 1),
    (@Q_ID, N'{"L": "How often do you ride a bike?", "R": "Twice a week."}', 1),
    (@Q_ID, N'{"L": "Does he drive to work?", "R": "Yes, he does."}', 1),
    (@Q_ID, N'{"L": "I ride my scooter", "R": "to the park."}', 1),
    (@Q_ID, N'{"L": "My father drives", "R": "me to school."}', 1),
    (@Q_ID, N'{"L": "We take the ferry", "R": "across the river."}', 1),
    (@Q_ID, N'{"L": "I never go", "R": "by helicopter."}', 1);
END

-- ==========================================================
-- UNIT 4: OUR SENSES (20 PAIRS)
-- ==========================================================
IF @U4 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U4, N'Nối từ và câu Unit 4', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Loud", "R": "Ồn ào"}', 1),
    (@Q_ID, N'{"L": "Quiet", "R": "Yên tĩnh"}', 1),
    (@Q_ID, N'{"L": "Soft", "R": "Mềm mại"}', 1),
    (@Q_ID, N'{"L": "Hard", "R": "Cứng"}', 1),
    (@Q_ID, N'{"L": "Juicy", "R": "Mọng nước"}', 1),
    (@Q_ID, N'{"L": "Burnt", "R": "Bị cháy khét"}', 1),
    (@Q_ID, N'{"L": "Fatty", "R": "Béo ngậy"}', 1),
    (@Q_ID, N'{"L": "Smell", "R": "Ngửi"}', 1),
    (@Q_ID, N'{"L": "Taste", "R": "Nếm"}', 1),
    (@Q_ID, N'{"L": "Touch", "R": "Sờ/Chạm"}', 1),
    (@Q_ID, N'{"L": "Look", "R": "Trông/Nhìn"}', 1),
    (@Q_ID, N'{"L": "Sound", "R": "Nghe có vẻ"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "Did you smell the soup?", "R": "Yes, it smelled great."}', 1),
    (@Q_ID, N'{"L": "Did you touch the rabbit?", "R": "Yes, it felt soft."}', 1),
    (@Q_ID, N'{"L": "Did you hear the music?", "R": "No, I didn''t."}', 1),
    (@Q_ID, N'{"L": "How did the cake taste?", "R": "It tasted sweet."}', 1),
    (@Q_ID, N'{"L": "The rock felt", "R": "hard and rough."}', 1),
    (@Q_ID, N'{"L": "The drums sounded", "R": "very loud."}', 1),
    (@Q_ID, N'{"L": "The flowers looked", "R": "beautiful."}', 1),
    (@Q_ID, N'{"L": "The coffee tasted", "R": "bitter."}', 1);
END

-- ==========================================================
-- UNIT 5: OUR HEALTH (20 PAIRS)
-- ==========================================================
IF @U5 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U5, N'Nối từ và câu Unit 5', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Headache", "R": "Đau đầu"}', 1),
    (@Q_ID, N'{"L": "Toothache", "R": "Đau răng"}', 1),
    (@Q_ID, N'{"L": "Stomachache", "R": "Đau bụng"}', 1),
    (@Q_ID, N'{"L": "Fever", "R": "Sốt"}', 1),
    (@Q_ID, N'{"L": "Cough", "R": "Ho"}', 1),
    (@Q_ID, N'{"L": "Sore throat", "R": "Đau họng"}', 1),
    (@Q_ID, N'{"L": "Runny nose", "R": "Sổ mũi"}', 1),
    (@Q_ID, N'{"L": "Dentist", "R": "Nha sĩ"}', 1),
    (@Q_ID, N'{"L": "Medicine", "R": "Thuốc"}', 1),
    (@Q_ID, N'{"L": "Rest", "R": "Nghỉ ngơi"}', 1),
    (@Q_ID, N'{"L": "Ginger tea", "R": "Trà gừng"}', 1),
    (@Q_ID, N'{"L": "Keep clean", "R": "Giữ sạch sẽ"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "What is the matter?", "R": "I have a cold."}', 1),
    (@Q_ID, N'{"L": "I have a toothache.", "R": "You should see a dentist."}', 1),
    (@Q_ID, N'{"L": "Should I eat candy?", "R": "No, you shouldn''t."}', 1),
    (@Q_ID, N'{"L": "I have a fever.", "R": "You should take some medicine."}', 1),
    (@Q_ID, N'{"L": "I didn''t feel well", "R": "yesterday."}', 1),
    (@Q_ID, N'{"L": "You should keep", "R": "your hands clean."}', 1),
    (@Q_ID, N'{"L": "Rest your eyes", "R": "when they are sore."}', 1),
    (@Q_ID, N'{"L": "Drink ginger tea", "R": "for a sore throat."}', 1);
END

-- ==========================================================
-- UNIT 6: THE WORLD OF SCHOOL (20 PAIRS)
-- ==========================================================
IF @U6 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U6, N'Nối từ và câu Unit 6', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "History", "R": "Lịch sử"}', 1),
    (@Q_ID, N'{"L": "Science", "R": "Khoa học"}', 1),
    (@Q_ID, N'{"L": "Math", "R": "Toán học"}', 1),
    (@Q_ID, N'{"L": "Art", "R": "Mỹ thuật"}', 1),
    (@Q_ID, N'{"L": "Literature", "R": "Ngữ văn"}', 1),
    (@Q_ID, N'{"L": "PE", "R": "Thể dục"}', 1),
    (@Q_ID, N'{"L": "Volunteer", "R": "Tình nguyện"}', 1),
    (@Q_ID, N'{"L": "Field trip", "R": "Chuyến dã ngoại"}', 1),
    (@Q_ID, N'{"L": "Poster", "R": "Áp phích"}', 1),
    (@Q_ID, N'{"L": "Club", "R": "Câu lạc bộ"}', 1),
    (@Q_ID, N'{"L": "Board games", "R": "Trò chơi bàn cờ"}', 1),
    (@Q_ID, N'{"L": "Read books", "R": "Đọc sách"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "What classes did you have?", "R": "I had Math and Art."}', 1),
    (@Q_ID, N'{"L": "When did you have Music?", "R": "On Tuesday."}', 1),
    (@Q_ID, N'{"L": "Where did you go?", "R": "I went to the zoo."}', 1),
    (@Q_ID, N'{"L": "Why did you go there?", "R": "To learn about animals."}', 1),
    (@Q_ID, N'{"L": "I made a poster", "R": "for my project."}', 1),
    (@Q_ID, N'{"L": "We joined", "R": "a science club."}', 1),
    (@Q_ID, N'{"L": "Did you go on", "R": "a field trip?"}', 1),
    (@Q_ID, N'{"L": "I did volunteer work", "R": "last summer."}', 1);
END

-- ==========================================================
-- UNIT 7: THE WORLD OF WORK (20 PAIRS)
-- ==========================================================
IF @U7 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U7, N'Nối từ và câu Unit 7', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Builder", "R": "Thợ xây"}', 1),
    (@Q_ID, N'{"L": "Mechanic", "R": "Thợ cơ khí"}', 1),
    (@Q_ID, N'{"L": "Tailor", "R": "Thợ may"}', 1),
    (@Q_ID, N'{"L": "Salesperson", "R": "Nhân viên bán hàng"}', 1),
    (@Q_ID, N'{"L": "Musician", "R": "Nhạc sĩ"}', 1),
    (@Q_ID, N'{"L": "Dentist", "R": "Nha sĩ"}', 1),
    (@Q_ID, N'{"L": "Babysitter", "R": "Người trông trẻ"}', 1),
    (@Q_ID, N'{"L": "Flight attendant", "R": "Tiếp viên hàng không"}', 1),
    (@Q_ID, N'{"L": "Athlete", "R": "Vận động viên"}', 1),
    (@Q_ID, N'{"L": "Magician", "R": "Ảo thuật gia"}', 1),
    (@Q_ID, N'{"L": "Repair", "R": "Sửa chữa"}', 1),
    (@Q_ID, N'{"L": "Perform", "R": "Biểu diễn"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "What do you want to be?", "R": "I want to be a pilot."}', 1),
    (@Q_ID, N'{"L": "Why do you like him?", "R": "Because he sings beautifully."}', 1),
    (@Q_ID, N'{"L": "A builder builds", "R": "houses."}', 1),
    (@Q_ID, N'{"L": "A tailor makes", "R": "clothes."}', 1),
    (@Q_ID, N'{"L": "The athlete runs", "R": "very fast."}', 1),
    (@Q_ID, N'{"L": "She performs", "R": "magic tricks."}', 1),
    (@Q_ID, N'{"L": "He repairs", "R": "cars and bikes."}', 1),
    (@Q_ID, N'{"L": "I will sell", "R": "delicious food."}', 1);
END

-- ==========================================================
-- UNIT 8: FANTASTIC HOLIDAYS (20 PAIRS)
-- ==========================================================
IF @U8 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U8, N'Nối từ và câu Unit 8', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    -- VOCAB (12)
    (@Q_ID, N'{"L": "Lantern", "R": "Đèn lồng"}', 1),
    (@Q_ID, N'{"L": "Costume", "R": "Trang phục hóa trang"}', 1),
    (@Q_ID, N'{"L": "Waterfall", "R": "Thác nước"}', 1),
    (@Q_ID, N'{"L": "Lucky money", "R": "Tiền lì xì"}', 1),
    (@Q_ID, N'{"L": "Lion dance", "R": "Múa lân"}', 1),
    (@Q_ID, N'{"L": "Resort", "R": "Khu nghỉ dưỡng"}', 1),
    (@Q_ID, N'{"L": "Campsite", "R": "Địa điểm cắm trại"}', 1),
    (@Q_ID, N'{"L": "Theme park", "R": "Công viên giải trí"}', 1),
    (@Q_ID, N'{"L": "Souvenir shop", "R": "Cửa hàng lưu niệm"}', 1),
    (@Q_ID, N'{"L": "Christmas", "R": "Giáng sinh"}', 1),
    (@Q_ID, N'{"L": "Halloween", "R": "Lễ hội ma"}', 1),
    (@Q_ID, N'{"L": "Tet Holiday", "R": "Tết Nguyên Đán"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "Show me the way", "R": "to the market."}', 1),
    (@Q_ID, N'{"L": "Go straight and", "R": "turn left."}', 1),
    (@Q_ID, N'{"L": "It is on", "R": "your right."}', 1),
    (@Q_ID, N'{"L": "What will you do?", "R": "I will buy souvenirs."}', 1),
    (@Q_ID, N'{"L": "I will light", "R": "lanterns."}', 1),
    (@Q_ID, N'{"L": "We will watch", "R": "a lion dance."}', 1),
    (@Q_ID, N'{"L": "Mid-Autumn Festival", "R": "is next week."}', 1),
    (@Q_ID, N'{"L": "Where will you go?", "R": "I will go to the beach."}', 1);
END

PRINT N'✅ ĐÃ TẠO XONG 180 CẶP CÂU HỎI (20 CẶP x 9 UNIT)!';
GO

USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO 20 CÂU SẮP XẾP (SCRAMBLE) CHO MỖI UNIT ===';

-- 1. DỌN DẸP DỮ LIỆU ROUND 2 CŨ
DELETE FROM QuestionOptions WHERE QuestionID IN (SELECT QuestionID FROM Questions WHERE QuestionType = 'scramble');
DELETE FROM Questions WHERE QuestionType = 'scramble';
PRINT N'🧹 Đã dọn dẹp dữ liệu Scramble cũ.';

-- Khai báo biến
DECLARE @Q_ID INT;
DECLARE @U0 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 0%');
DECLARE @U1 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 1%');
DECLARE @U2 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 2%');
DECLARE @U3 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 3%');
DECLARE @U4 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 4%');
DECLARE @U5 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 5%');
DECLARE @U6 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 6%');
DECLARE @U7 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 7%');
DECLARE @U8 INT = (SELECT TopicID FROM Topics WHERE TopicName LIKE N'Unit 8%');

-- ==========================================================
-- UNIT 0: GETTING STARTED (Weather, Seasons, Dates)
-- ==========================================================
IF @U0 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U0, N'Sắp xếp câu Unit 0', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What is the weather like in Hanoi', 1),
    (@Q_ID, N'It is hot and sunny today', 1),
    (@Q_ID, N'My favorite season is summer', 1),
    (@Q_ID, N'Do you like the rainy season', 1),
    (@Q_ID, N'Is your birthday in June', 1),
    (@Q_ID, N'Twenty plus five equals twenty-five', 1),
    (@Q_ID, N'It is cold and snowy in winter', 1),
    (@Q_ID, N'Flowers bloom in the spring', 1),
    (@Q_ID, N'There are twelve months in a year', 1),
    (@Q_ID, N'I do not like cold weather', 1),
    (@Q_ID, N'What is the weather like today', 1),
    (@Q_ID, N'It rains a lot in the rainy season', 1),
    (@Q_ID, N'My birthday is in December', 1),
    (@Q_ID, N'Fifty minus twenty equals thirty', 1),
    (@Q_ID, N'The dry season is very hot', 1),
    (@Q_ID, N'We often go swimming in summer', 1),
    (@Q_ID, N'Leaves fall from trees in autumn', 1),
    (@Q_ID, N'It is cool and windy today', 1),
    (@Q_ID, N'One hundred plus two hundred equals three hundred', 1),
    (@Q_ID, N'Tet Holiday is usually in January or February', 1);
END

-- ==========================================================
-- UNIT 1: ANIMAL HABITATS (Where do they live?)
-- ==========================================================
IF @U1 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U1, N'Sắp xếp câu Unit 1', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'Camels live in the desert', 1),
    (@Q_ID, N'Polar bears live in the polar region', 1),
    (@Q_ID, N'Do bees live in hives or nests', 1),
    (@Q_ID, N'They live in hives', 1),
    (@Q_ID, N'Giraffes use their tongues to clean their ears', 1),
    (@Q_ID, N'Goats use their horns to fight', 1),
    (@Q_ID, N'Birds build nests in the trees', 1),
    (@Q_ID, N'Cats use their claws to catch mice', 1),
    (@Q_ID, N'Monkeys live in the forest', 1),
    (@Q_ID, N'Penguins live on the ice', 1),
    (@Q_ID, N'A kangaroo has a pouch', 1),
    (@Q_ID, N'Birds use their beaks to eat', 1),
    (@Q_ID, N'Bats sleep in dark caves', 1),
    (@Q_ID, N'Tigers have very sharp claws', 1),
    (@Q_ID, N'Hippos like to play in the mud', 1),
    (@Q_ID, N'Crocodiles live in the river', 1),
    (@Q_ID, N'The desert is a dry place', 1),
    (@Q_ID, N'The ocean is very deep and blue', 1),
    (@Q_ID, N'Animals need food and water to live', 1),
    (@Q_ID, N'We should protect animal habitats', 1);
END

-- ==========================================================
-- UNIT 2: LET''S EAT! (Food, Requests)
-- ==========================================================
IF @U2 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U2, N'Sắp xếp câu Unit 2', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'May I have some chips please', 1),
    (@Q_ID, N'Would you like some ice cream', 1),
    (@Q_ID, N'Yes please I am very hungry', 1),
    (@Q_ID, N'No thanks I am full', 1),
    (@Q_ID, N'Is there any oil in the bottle', 1),
    (@Q_ID, N'Yes there is a lot of oil', 1),
    (@Q_ID, N'Are there any olives in the jar', 1),
    (@Q_ID, N'No there are not many olives', 1),
    (@Q_ID, N'I would like a bowl of noodles', 1),
    (@Q_ID, N'This pizza tastes delicious', 1),
    (@Q_ID, N'Lemons taste very sour', 1),
    (@Q_ID, N'These chili peppers are spicy', 1),
    (@Q_ID, N'Can you pass me the salt', 1),
    (@Q_ID, N'I need a box of cereal', 1),
    (@Q_ID, N'There is a little soda in the can', 1),
    (@Q_ID, N'We eat rice every day', 1),
    (@Q_ID, N'Chocolate is very sweet', 1),
    (@Q_ID, N'Do not eat too much sugar', 1),
    (@Q_ID, N'My favorite food is chicken', 1),
    (@Q_ID, N'Let us make a cake together', 1);
END

-- ==========================================================
-- UNIT 3: ON THE MOVE! (Transport)
-- ==========================================================
IF @U3 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U3, N'Sắp xếp câu Unit 3', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'Do you go to school by bus', 1),
    (@Q_ID, N'No I go to school on foot', 1),
    (@Q_ID, N'My father drives to work', 1),
    (@Q_ID, N'How often do you ride your bike', 1),
    (@Q_ID, N'I ride my bike twice a week', 1),
    (@Q_ID, N'We took a ferry across the river', 1),
    (@Q_ID, N'The subway is very fast', 1),
    (@Q_ID, N'Have you ever flown in a helicopter', 1),
    (@Q_ID, N'I ride my scooter in the park', 1),
    (@Q_ID, N'He goes to school by motorcycle', 1),
    (@Q_ID, N'We are going to travel by airplane', 1),
    (@Q_ID, N'Please get on the bus', 1),
    (@Q_ID, N'We get off at the next station', 1),
    (@Q_ID, N'It is safe to walk on the sidewalk', 1),
    (@Q_ID, N'She never rides a horse', 1),
    (@Q_ID, N'Boats sail on the water', 1),
    (@Q_ID, N'I like to row a boat', 1),
    (@Q_ID, N'Cars must stop at the red light', 1),
    (@Q_ID, N'Can you ride a bicycle', 1),
    (@Q_ID, N'Traveling by train is interesting', 1);
END

-- ==========================================================
-- UNIT 4: OUR SENSES (Adjectives, Past Simple)
-- ==========================================================
IF @U4 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U4, N'Sắp xếp câu Unit 4', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'Did you smell the soup', 1),
    (@Q_ID, N'Yes it smelled delicious', 1),
    (@Q_ID, N'Did you hear the music last night', 1),
    (@Q_ID, N'Yes it sounded very loud', 1),
    (@Q_ID, N'Did you touch the rabbit', 1),
    (@Q_ID, N'Yes it felt very soft', 1),
    (@Q_ID, N'The rock felt hard and rough', 1),
    (@Q_ID, N'The coffee tasted bitter', 1),
    (@Q_ID, N'The flowers looked beautiful', 1),
    (@Q_ID, N'The lemon tasted sour', 1),
    (@Q_ID, N'Did you see the rainbow', 1),
    (@Q_ID, N'The garbage smelled bad', 1),
    (@Q_ID, N'The music was too quiet', 1),
    (@Q_ID, N'I like sweet candy', 1),
    (@Q_ID, N'This chips are too salty', 1),
    (@Q_ID, N'The pillow feels soft', 1),
    (@Q_ID, N'Smoke smells like burnt wood', 1),
    (@Q_ID, N'Durian has a strong smell', 1),
    (@Q_ID, N'We use our eyes to see', 1),
    (@Q_ID, N'We use our ears to hear', 1);
END

-- ==========================================================
-- UNIT 5: OUR HEALTH (Illnesses, Advice)
-- ==========================================================
IF @U5 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U5, N'Sắp xếp câu Unit 5', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What is the matter with you', 1),
    (@Q_ID, N'I have a bad headache', 1),
    (@Q_ID, N'You should take some medicine', 1),
    (@Q_ID, N'I have a toothache', 1),
    (@Q_ID, N'You should see a dentist', 1),
    (@Q_ID, N'He has a sore throat', 1),
    (@Q_ID, N'You should drink ginger tea', 1),
    (@Q_ID, N'I did not feel well yesterday', 1),
    (@Q_ID, N'She had a high fever', 1),
    (@Q_ID, N'You should rest in bed', 1),
    (@Q_ID, N'You should keep your hands clean', 1),
    (@Q_ID, N'Do not eat too much candy', 1),
    (@Q_ID, N'You should exercise every day', 1),
    (@Q_ID, N'My stomachache is getting worse', 1),
    (@Q_ID, N'I have a runny nose', 1),
    (@Q_ID, N'You should rest your eyes', 1),
    (@Q_ID, N'Eating vegetables is good for health', 1),
    (@Q_ID, N'Drink plenty of water', 1),
    (@Q_ID, N'Did you take the medicine', 1),
    (@Q_ID, N'I feel much better now', 1);
END

-- ==========================================================
-- UNIT 6: THE WORLD OF SCHOOL (Past activities)
-- ==========================================================
IF @U6 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U6, N'Sắp xếp câu Unit 6', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What classes did you have last week', 1),
    (@Q_ID, N'I had math and literature', 1),
    (@Q_ID, N'When did you have music class', 1),
    (@Q_ID, N'I had music on Tuesday and Thursday', 1),
    (@Q_ID, N'Where did you go last summer', 1),
    (@Q_ID, N'I went on a field trip to the zoo', 1),
    (@Q_ID, N'Why did you go to the zoo', 1),
    (@Q_ID, N'We went there to learn about animals', 1),
    (@Q_ID, N'I joined a science club', 1),
    (@Q_ID, N'We played board games yesterday', 1),
    (@Q_ID, N'I made a poster for my project', 1),
    (@Q_ID, N'Did you do volunteer work', 1),
    (@Q_ID, N'We read books in the library', 1),
    (@Q_ID, N'I love computer science class', 1),
    (@Q_ID, N'Physical education is my favorite subject', 1),
    (@Q_ID, N'We learned about history', 1),
    (@Q_ID, N'Our school is very big', 1),
    (@Q_ID, N'My teacher is very kind', 1),
    (@Q_ID, N'We usually play sports after school', 1),
    (@Q_ID, N'Did you make a video', 1);
END

-- ==========================================================
-- UNIT 7: THE WORLD OF WORK (Jobs)
-- ==========================================================
IF @U7 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U7, N'Sắp xếp câu Unit 7', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What do you want to be one day', 1),
    (@Q_ID, N'I want to be a salesperson', 1),
    (@Q_ID, N'I will sell delicious foods', 1),
    (@Q_ID, N'Why do you like this singer', 1),
    (@Q_ID, N'Because she sings beautifully', 1),
    (@Q_ID, N'A builder builds houses', 1),
    (@Q_ID, N'A tailor makes clothes', 1),
    (@Q_ID, N'The athlete runs very fast', 1),
    (@Q_ID, N'A flight attendant works on a plane', 1),
    (@Q_ID, N'The magician performs magic tricks', 1),
    (@Q_ID, N'A mechanic repairs cars', 1),
    (@Q_ID, N'A dentist looks after your teeth', 1),
    (@Q_ID, N'I want to help sick people', 1),
    (@Q_ID, N'He works very hard', 1),
    (@Q_ID, N'My mother is a teacher', 1),
    (@Q_ID, N'The musician plays the guitar well', 1),
    (@Q_ID, N'A babysitter looks after children', 1),
    (@Q_ID, N'What does your father do', 1),
    (@Q_ID, N'He is a police officer', 1),
    (@Q_ID, N'I respect everyone jobs', 1);
END

-- ==========================================================
-- UNIT 8: FANTASTIC HOLIDAYS (Future plans)
-- ==========================================================
IF @U8 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U8, N'Sắp xếp câu Unit 8', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'Could you show me the way to the market', 1),
    (@Q_ID, N'Go straight and turn left', 1),
    (@Q_ID, N'It is on your right', 1),
    (@Q_ID, N'The Mid Autumn Festival is next week', 1),
    (@Q_ID, N'What will you do there', 1),
    (@Q_ID, N'I will light lanterns', 1),
    (@Q_ID, N'We will watch a lion dance', 1),
    (@Q_ID, N'I will go to my grandma house', 1),
    (@Q_ID, N'We will eat lots of mooncakes', 1),
    (@Q_ID, N'I will wear a costume for Halloween', 1),
    (@Q_ID, N'We will visit a theme park', 1),
    (@Q_ID, N'I am going to buy souvenirs', 1),
    (@Q_ID, N'Where is the waterfall', 1),
    (@Q_ID, N'We will stay at a resort', 1),
    (@Q_ID, N'Children get lucky money at Tet', 1),
    (@Q_ID, N'We clean our house before Tet', 1),
    (@Q_ID, N'Do you like Christmas', 1),
    (@Q_ID, N'We will have a great time', 1),
    (@Q_ID, N'Turn right at the souvenir shop', 1),
    (@Q_ID, N'I am excited for the holidays', 1);
END

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU SẮP XẾP (20 CÂU x 9 UNIT)!';
GO

USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO DỮ LIỆU ROUND 3 (TRẮC NGHIỆM) ===';

-- 1. DỌN DẸP DỮ LIỆU ROUND 3 CŨ (Để tránh trùng lặp)
DELETE FROM QuestionOptions WHERE QuestionID IN (SELECT QuestionID FROM Questions WHERE QuestionType = 'multiple_choice');
DELETE FROM Questions WHERE QuestionType = 'multiple_choice';
PRINT N'🧹 Đã xóa câu hỏi trắc nghiệm cũ.';

-- 2. TẠO THỦ TỤC TẠM ĐỂ CHÈN CÂU HỎI NHANH (Giúp code ngắn gọn)
IF OBJECT_ID('tempdb..#AddQuiz') IS NOT NULL DROP PROCEDURE #AddQuiz;
GO

CREATE PROCEDURE #AddQuiz
    @UnitName NVARCHAR(100), -- Tên Unit (VD: 'Unit 0')
    @QuestionText NVARCHAR(MAX),
    @CorrectAns NVARCHAR(255),
    @Wrong1 NVARCHAR(255),
    @Wrong2 NVARCHAR(255),
    @Wrong3 NVARCHAR(255)
AS
BEGIN
    DECLARE @TopicID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE @UnitName + N'%');
    DECLARE @QID INT;

    IF @TopicID IS NOT NULL
    BEGIN
        -- Chèn câu hỏi
        INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
        VALUES (@TopicID, @QuestionText, 'multiple_choice', @CorrectAns);
        
        SET @QID = SCOPE_IDENTITY();

        -- Chèn 4 đáp án (1 Đúng, 3 Sai)
        INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
        (@QID, @CorrectAns, 1),
        (@QID, @Wrong1, 0),
        (@QID, @Wrong2, 0),
        (@QID, @Wrong3, 0);
    END
END;
GO

-- ======================================================================================
-- 3. BẮT ĐẦU NẠP DỮ LIỆU (20 CÂU/UNIT)
-- ======================================================================================

PRINT N'--- Đang nạp Unit 0: Getting Started ---';
EXEC #AddQuiz N'Unit 0', N'What is the weather like in winter?', N'It is cold and snowy.', N'It is hot.', N'It is warm.', N'It is rainy.';
EXEC #AddQuiz N'Unit 0', N'Twenty plus ten equals ______.', N'thirty', N'forty', N'twenty', N'fifty';
EXEC #AddQuiz N'Unit 0', N'What season comes after spring?', N'Summer', N'Winter', N'Fall', N'Rainy season';
EXEC #AddQuiz N'Unit 0', N'Is your birthday ______ June?', N'in', N'on', N'at', N'of';
EXEC #AddQuiz N'Unit 0', N'What is the weather like today?', N'It is sunny.', N'I like summer.', N'Yes, it is.', N'No, I do not.';
EXEC #AddQuiz N'Unit 0', N'Fifty minus twenty equals ______.', N'thirty', N'seventy', N'forty', N'ten';
EXEC #AddQuiz N'Unit 0', N'My favorite season is ______.', N'fall', N'hot', N'cold', N'weather';
EXEC #AddQuiz N'Unit 0', N'There are ______ months in a year.', N'twelve', N'ten', N'twenty', N'seven';
EXEC #AddQuiz N'Unit 0', N'Do you like the rainy season?', N'No, I don''t.', N'Yes, I am.', N'No, it isn''t.', N'Yes, it is.';
EXEC #AddQuiz N'Unit 0', N'One hundred plus five equals ______.', N'one hundred and five', N'one hundred', N'five hundred', N'fifty';
EXEC #AddQuiz N'Unit 0', N'It is often ______ in the rainy season.', N'wet', N'dry', N'snowy', N'hot';
EXEC #AddQuiz N'Unit 0', N'When is Christmas?', N'In December', N'In June', N'In March', N'In August';
EXEC #AddQuiz N'Unit 0', N'The weather in the desert is usually ______.', N'hot and dry', N'cold and wet', N'snowy', N'rainy';
EXEC #AddQuiz N'Unit 0', N'Does it snow in Vietnam?', N'Usually no', N'Yes, every day', N'Always', N'In Ho Chi Minh City';
EXEC #AddQuiz N'Unit 0', N'Which month is in spring?', N'March', N'August', N'October', N'December';
EXEC #AddQuiz N'Unit 0', N'Ten ______ ten equals twenty.', N'plus', N'minus', N'times', N'divided by';
EXEC #AddQuiz N'Unit 0', N'I wear a coat when it is ______.', N'cold', N'hot', N'warm', N'sunny';
EXEC #AddQuiz N'Unit 0', N'What comes after July?', N'August', N'June', N'September', N'May';
EXEC #AddQuiz N'Unit 0', N'Is it cloudy today?', N'Yes, it is.', N'Yes, I do.', N'No, I don''t.', N'Yes, I am.';
EXEC #AddQuiz N'Unit 0', N'______ is the first month of the year.', N'January', N'February', N'December', N'March';


PRINT N'--- Đang nạp Unit 1: Animal Habitats ---';
EXEC #AddQuiz N'Unit 1', N'Where do camels live?', N'In the desert', N'In the ocean', N'In the forest', N'In the cave';
EXEC #AddQuiz N'Unit 1', N'Where do polar bears live?', N'In the polar region', N'In the jungle', N'In the river', N'In the nest';
EXEC #AddQuiz N'Unit 1', N'Bees live in ______.', N'hives', N'caves', N'nests', N'water';
EXEC #AddQuiz N'Unit 1', N'Birds use their ______ to fly.', N'wings', N'beaks', N'claws', N'ears';
EXEC #AddQuiz N'Unit 1', N'Giraffes have very long ______.', N'tongues', N'beaks', N'pouches', N'hives';
EXEC #AddQuiz N'Unit 1', N'Goats use their horns to ______.', N'fight', N'fly', N'swim', N'sing';
EXEC #AddQuiz N'Unit 1', N'A kangaroo has a ______.', N'pouch', N'horn', N'beak', N'hive';
EXEC #AddQuiz N'Unit 1', N'Monkeys live in the ______.', N'forest', N'ocean', N'ice', N'sky';
EXEC #AddQuiz N'Unit 1', N'Tigers have sharp ______.', N'claws', N'horns', N'pouches', N'wings';
EXEC #AddQuiz N'Unit 1', N'Hippos like to play in the ______.', N'mud', N'ice', N'tree', N'sky';
EXEC #AddQuiz N'Unit 1', N'Do bears sleep in caves?', N'Yes, they do.', N'No, they don''t.', N'Yes, it is.', N'No, it isn''t.';
EXEC #AddQuiz N'Unit 1', N'Penguins live on the ______.', N'ice', N'sand', N'tree', N'roof';
EXEC #AddQuiz N'Unit 1', N'Birds build ______ in trees.', N'nests', N'caves', N'hives', N'deserts';
EXEC #AddQuiz N'Unit 1', N'Crocodiles live in the ______.', N'river', N'desert', N'mountain', N'sky';
EXEC #AddQuiz N'Unit 1', N'A ______ has a hard shell.', N'turtle', N'cat', N'dog', N'bird';
EXEC #AddQuiz N'Unit 1', N'Elephants have a long ______.', N'trunk', N'beak', N'claw', N'horn';
EXEC #AddQuiz N'Unit 1', N'Fish live in the ______.', N'water', N'air', N'forest', N'sand';
EXEC #AddQuiz N'Unit 1', N'Bats sleep during the ______.', N'day', N'night', N'morning', N'afternoon';
EXEC #AddQuiz N'Unit 1', N'The desert is very ______.', N'dry', N'wet', N'cold', N'rainy';
EXEC #AddQuiz N'Unit 1', N'We should ______ animal habitats.', N'protect', N'destroy', N'ignore', N'burn';


PRINT N'--- Đang nạp Unit 2: Let''s Eat! ---';
EXEC #AddQuiz N'Unit 2', N'Lemons taste ______.', N'sour', N'sweet', N'spicy', N'salty';
EXEC #AddQuiz N'Unit 2', N'Chili peppers are ______.', N'spicy', N'sweet', N'bitter', N'cold';
EXEC #AddQuiz N'Unit 2', N'Would you like ______ ice cream?', N'some', N'a', N'an', N'any';
EXEC #AddQuiz N'Unit 2', N'Can I have a ______ of water?', N'bottle', N'piece', N'loaf', N'slice';
EXEC #AddQuiz N'Unit 2', N'I would like a ______ of noodles.', N'bowl', N'box', N'jar', N'bottle';
EXEC #AddQuiz N'Unit 2', N'Chocolate is usually ______.', N'sweet', N'sour', N'spicy', N'salty';
EXEC #AddQuiz N'Unit 2', N'______ there any olives in the jar?', N'Are', N'Is', N'Do', N'Does';
EXEC #AddQuiz N'Unit 2', N'Yes, there are ______.', N'a few', N'a little', N'much', N'one';
EXEC #AddQuiz N'Unit 2', N'Is there any soda?', N'No, there isn''t much.', N'No, there aren''t.', N'Yes, there are many.', N'Yes, I do.';
EXEC #AddQuiz N'Unit 2', N'A ______ of cereal.', N'box', N'bottle', N'jar', N'loaf';
EXEC #AddQuiz N'Unit 2', N'A ______ of bread.', N'loaf', N'bowl', N'bottle', N'can';
EXEC #AddQuiz N'Unit 2', N'Coffee without sugar tastes ______.', N'bitter', N'sweet', N'salty', N'spicy';
EXEC #AddQuiz N'Unit 2', N'Potato chips are ______.', N'salty', N'sweet', N'sour', N'bitter';
EXEC #AddQuiz N'Unit 2', N'May I have some cake?', N'Yes, please.', N'No, I don''t.', N'Yes, I am.', N'You are welcome.';
EXEC #AddQuiz N'Unit 2', N'We eat ______ for breakfast.', N'bread', N'water', N'soda', N'oil';
EXEC #AddQuiz N'Unit 2', N'Don''t eat too much ______.', N'candy', N'vegetables', N'fruit', N'water';
EXEC #AddQuiz N'Unit 2', N'A ______ of soda.', N'can', N'loaf', N'piece', N'bowl';
EXEC #AddQuiz N'Unit 2', N'I need a ______ of oil.', N'bottle', N'box', N'piece', N'loaf';
EXEC #AddQuiz N'Unit 2', N'This pizza ______ delicious.', N'tastes', N'looks', N'sounds', N'feels';
EXEC #AddQuiz N'Unit 2', N'Do you like beans?', N'Yes, I do.', N'Yes, I am.', N'No, I am not.', N'Yes, it is.';


PRINT N'--- Đang nạp Unit 3: On the Move! ---';
EXEC #AddQuiz N'Unit 3', N'How do you go to school?', N'By bus', N'On bus', N'In bus', N'At bus';
EXEC #AddQuiz N'Unit 3', N'We go to the park ______ foot.', N'on', N'by', N'in', N'with';
EXEC #AddQuiz N'Unit 3', N'Does your father ______ a car?', N'drive', N'ride', N'fly', N'sail';
EXEC #AddQuiz N'Unit 3', N'I ______ my bike to school.', N'ride', N'drive', N'fly', N'run';
EXEC #AddQuiz N'Unit 3', N'A ______ flies in the sky.', N'helicopter', N'boat', N'train', N'subway';
EXEC #AddQuiz N'Unit 3', N'The ______ runs underground.', N'subway', N'bus', N'taxi', N'airplane';
EXEC #AddQuiz N'Unit 3', N'We took a ______ across the river.', N'ferry', N'bike', N'car', N'train';
EXEC #AddQuiz N'Unit 3', N'He goes to work ______ motorcycle.', N'by', N'on', N'in', N'at';
EXEC #AddQuiz N'Unit 3', N'______ often do you ride your bike?', N'How', N'What', N'Where', N'When';
EXEC #AddQuiz N'Unit 3', N'I ride my scooter ______ a week.', N'twice', N'two', N'second', N'twelve';
EXEC #AddQuiz N'Unit 3', N'Cars must stop at the ______ light.', N'red', N'green', N'yellow', N'blue';
EXEC #AddQuiz N'Unit 3', N'A pilot flies an ______.', N'airplane', N'bus', N'boat', N'taxi';
EXEC #AddQuiz N'Unit 3', N'Please ______ on the bus.', N'get', N'go', N'take', N'make';
EXEC #AddQuiz N'Unit 3', N'We get ______ the train at the station.', N'off', N'out', N'up', N'down';
EXEC #AddQuiz N'Unit 3', N'It is safe to walk on the ______.', N'sidewalk', N'street', N'road', N'river';
EXEC #AddQuiz N'Unit 3', N'Do you ever go by helicopter?', N'No, never.', N'Yes, I am.', N'No, I don''t.', N'Yes, it is.';
EXEC #AddQuiz N'Unit 3', N'Boats sail on the ______.', N'water', N'road', N'sky', N'land';
EXEC #AddQuiz N'Unit 3', N'I like to ______ a boat.', N'row', N'drive', N'ride', N'climb';
EXEC #AddQuiz N'Unit 3', N'Always wear a ______ on a motorbike.', N'helmet', N'hat', N'cap', N'mask';
EXEC #AddQuiz N'Unit 3', N'Is the subway fast?', N'Yes, it is.', N'Yes, I do.', N'No, I don''t.', N'No, I am not.';


PRINT N'--- Đang nạp Unit 4: Our Senses ---';
EXEC #AddQuiz N'Unit 4', N'We use our ______ to smell.', N'nose', N'eyes', N'ears', N'mouth';
EXEC #AddQuiz N'Unit 4', N'We use our ______ to hear.', N'ears', N'eyes', N'hands', N'tongue';
EXEC #AddQuiz N'Unit 4', N'Did you ______ the soup?', N'taste', N'hear', N'look', N'listen';
EXEC #AddQuiz N'Unit 4', N'The music sounded very ______.', N'loud', N'delicious', N'spicy', N'salty';
EXEC #AddQuiz N'Unit 4', N'The rabbit felt very ______.', N'soft', N'hard', N'loud', N'sweet';
EXEC #AddQuiz N'Unit 4', N'The rock felt ______.', N'hard', N'soft', N'quiet', N'sour';
EXEC #AddQuiz N'Unit 4', N'The flowers looked ______.', N'beautiful', N'loud', N'salty', N'hard';
EXEC #AddQuiz N'Unit 4', N'The lemon tasted ______.', N'sour', N'loud', N'soft', N'quiet';
EXEC #AddQuiz N'Unit 4', N'Did you ______ the rainbow?', N'see', N'hear', N'smell', N'taste';
EXEC #AddQuiz N'Unit 4', N'The garbage smelled ______.', N'bad', N'good', N'beautiful', N'soft';
EXEC #AddQuiz N'Unit 4', N'The library is very ______.', N'quiet', N'loud', N'spicy', N'hard';
EXEC #AddQuiz N'Unit 4', N'I can ______ the birds singing.', N'hear', N'smell', N'touch', N'taste';
EXEC #AddQuiz N'Unit 4', N'This pillow feels ______.', N'soft', N'hard', N'loud', N'sour';
EXEC #AddQuiz N'Unit 4', N'Smoke smells like ______ wood.', N'burnt', N'sweet', N'soft', N'juicy';
EXEC #AddQuiz N'Unit 4', N'Durian has a strong ______.', N'smell', N'sound', N'look', N'feel';
EXEC #AddQuiz N'Unit 4', N'These chips are too ______.', N'salty', N'loud', N'quiet', N'soft';
EXEC #AddQuiz N'Unit 4', N'How does the cake taste?', N'It tastes sweet.', N'It sounds sweet.', N'It looks loud.', N'It feels spicy.';
EXEC #AddQuiz N'Unit 4', N'Did you touch the snake?', N'Yes, it felt cold.', N'Yes, it smelled good.', N'No, it was loud.', N'Yes, it tasted sweet.';
EXEC #AddQuiz N'Unit 4', N'The watermelon is very ______.', N'juicy', N'dry', N'loud', N'burnt';
EXEC #AddQuiz N'Unit 4', N'That picture looks ______.', N'ugly', N'loud', N'spicy', N'sour';


PRINT N'--- Đang nạp Unit 5: Our Health ---';
EXEC #AddQuiz N'Unit 5', N'What is the ______ with you?', N'matter', N'wrong', N'problem', N'happen';
EXEC #AddQuiz N'Unit 5', N'I have a ______ headache.', N'bad', N'wrong', N'sick', N'hurt';
EXEC #AddQuiz N'Unit 5', N'You should ______ some medicine.', N'take', N'eat', N'drink', N'do';
EXEC #AddQuiz N'Unit 5', N'I have a toothache. - You should see a ______.', N'dentist', N'doctor', N'teacher', N'nurse';
EXEC #AddQuiz N'Unit 5', N'He has a sore ______.', N'throat', N'neck', N'hand', N'leg';
EXEC #AddQuiz N'Unit 5', N'You should ______ ginger tea.', N'drink', N'eat', N'take', N'do';
EXEC #AddQuiz N'Unit 5', N'I ______ feel well yesterday.', N'didn''t', N'don''t', N'doesn''t', N'wasn''t';
EXEC #AddQuiz N'Unit 5', N'She ______ a high fever last night.', N'had', N'has', N'have', N'having';
EXEC #AddQuiz N'Unit 5', N'You should ______ in bed.', N'rest', N'play', N'run', N'work';
EXEC #AddQuiz N'Unit 5', N'You should keep your hands ______.', N'clean', N'dirty', N'wet', N'cold';
EXEC #AddQuiz N'Unit 5', N'Don''t eat too much ______.', N'candy', N'water', N'fruit', N'vegetables';
EXEC #AddQuiz N'Unit 5', N'You should ______ exercise every day.', N'do', N'make', N'play', N'go';
EXEC #AddQuiz N'Unit 5', N'My stomachache is getting ______.', N'worse', N'bad', N'good', N'better';
EXEC #AddQuiz N'Unit 5', N'I have a ______ nose.', N'runny', N'running', N'rainy', N'sunny';
EXEC #AddQuiz N'Unit 5', N'You should rest your ______.', N'eyes', N'ears', N'mouth', N'nose';
EXEC #AddQuiz N'Unit 5', N'Eating vegetables is ______ for health.', N'good', N'bad', N'wrong', N'sick';
EXEC #AddQuiz N'Unit 5', N'Drink plenty of ______.', N'water', N'soda', N'oil', N'coffee';
EXEC #AddQuiz N'Unit 5', N'Did you take the medicine?', N'Yes, I did.', N'Yes, I do.', N'No, I don''t.', N'Yes, I am.';
EXEC #AddQuiz N'Unit 5', N'I feel much ______ now.', N'better', N'good', N'well', N'bad';
EXEC #AddQuiz N'Unit 5', N'You shouldn''t stay up ______.', N'late', N'early', N'morning', N'noon';


PRINT N'--- Đang nạp Unit 6: The World of School ---';
EXEC #AddQuiz N'Unit 6', N'What ______ did you have last week?', N'classes', N'class', N'school', N'lesson';
EXEC #AddQuiz N'Unit 6', N'I ______ math and literature.', N'had', N'have', N'has', N'having';
EXEC #AddQuiz N'Unit 6', N'______ did you have music class?', N'When', N'Where', N'What', N'Who';
EXEC #AddQuiz N'Unit 6', N'I had music ______ Tuesday.', N'on', N'in', N'at', N'of';
EXEC #AddQuiz N'Unit 6', N'Where did you go last summer?', N'I went to the zoo.', N'I go to the zoo.', N'I going to the zoo.', N'I goes to the zoo.';
EXEC #AddQuiz N'Unit 6', N'I went on a ______ trip.', N'field', N'school', N'class', N'home';
EXEC #AddQuiz N'Unit 6', N'Why did you go to the zoo?', N'To learn about animals.', N'To buy food.', N'To sleep.', N'To swim.';
EXEC #AddQuiz N'Unit 6', N'I ______ a science club.', N'joined', N'join', N'joins', N'joining';
EXEC #AddQuiz N'Unit 6', N'We ______ board games yesterday.', N'played', N'play', N'plays', N'playing';
EXEC #AddQuiz N'Unit 6', N'I made a ______ for my project.', N'poster', N'video', N'book', N'picture';
EXEC #AddQuiz N'Unit 6', N'Did you do ______ work?', N'volunteer', N'home', N'class', N'school';
EXEC #AddQuiz N'Unit 6', N'We read books in the ______.', N'library', N'gym', N'canteen', N'pool';
EXEC #AddQuiz N'Unit 6', N'I love ______ science class.', N'computer', N'math', N'music', N'art';
EXEC #AddQuiz N'Unit 6', N'Physical ______ is my favorite subject.', N'education', N'learning', N'class', N'school';
EXEC #AddQuiz N'Unit 6', N'We learned about ______ in History class.', N'the past', N'numbers', N'colors', N'animals';
EXEC #AddQuiz N'Unit 6', N'Our school is very ______.', N'big', N'tall', N'long', N'short';
EXEC #AddQuiz N'Unit 6', N'My teacher is very ______.', N'kind', N'angry', N'bad', N'sad';
EXEC #AddQuiz N'Unit 6', N'We usually ______ sports after school.', N'play', N'do', N'make', N'go';
EXEC #AddQuiz N'Unit 6', N'Did you make a video?', N'Yes, I did.', N'Yes, I do.', N'No, I don''t.', N'Yes, I am.';
EXEC #AddQuiz N'Unit 6', N'Art is about ______.', N'drawing', N'singing', N'running', N'counting';


PRINT N'--- Đang nạp Unit 7: The World of Work ---';
EXEC #AddQuiz N'Unit 7', N'What do you want to ______ one day?', N'be', N'do', N'make', N'have';
EXEC #AddQuiz N'Unit 7', N'I want to be a ______.', N'salesperson', N'sell', N'selling', N'sold';
EXEC #AddQuiz N'Unit 7', N'I will ______ delicious foods.', N'sell', N'buy', N'eat', N'drink';
EXEC #AddQuiz N'Unit 7', N'Why do you like this singer?', N'Because she sings beautifully.', N'Because she runs fast.', N'Because she cooks well.', N'Because she builds houses.';
EXEC #AddQuiz N'Unit 7', N'A builder ______ houses.', N'builds', N'makes', N'does', N'creates';
EXEC #AddQuiz N'Unit 7', N'A tailor ______ clothes.', N'makes', N'wears', N'buys', N'sells';
EXEC #AddQuiz N'Unit 7', N'The athlete runs very ______.', N'fast', N'slow', N'good', N'bad';
EXEC #AddQuiz N'Unit 7', N'A flight attendant works on a ______.', N'plane', N'bus', N'train', N'ship';
EXEC #AddQuiz N'Unit 7', N'The magician ______ magic tricks.', N'performs', N'plays', N'does', N'makes';
EXEC #AddQuiz N'Unit 7', N'A mechanic ______ cars.', N'repairs', N'drives', N'rides', N'buys';
EXEC #AddQuiz N'Unit 7', N'A dentist looks after your ______.', N'teeth', N'eyes', N'ears', N'hands';
EXEC #AddQuiz N'Unit 7', N'I want to help ______ people.', N'sick', N'healthy', N'rich', N'poor';
EXEC #AddQuiz N'Unit 7', N'He works very ______.', N'hard', N'hardly', N'good', N'bad';
EXEC #AddQuiz N'Unit 7', N'My mother is a ______.', N'teacher', N'teach', N'teaching', N'taught';
EXEC #AddQuiz N'Unit 7', N'The musician plays the ______ well.', N'guitar', N'football', N'tennis', N'game';
EXEC #AddQuiz N'Unit 7', N'A babysitter looks ______ children.', N'after', N'at', N'for', N'up';
EXEC #AddQuiz N'Unit 7', N'What does your father do?', N'He is a police officer.', N'He is kind.', N'He likes football.', N'He is at home.';
EXEC #AddQuiz N'Unit 7', N'I respect everyone''s ______.', N'jobs', N'hobbies', N'names', N'houses';
EXEC #AddQuiz N'Unit 7', N'A salesperson works in a ______.', N'shop', N'hospital', N'school', N'park';
EXEC #AddQuiz N'Unit 7', N'An artist paints ______.', N'pictures', N'houses', N'walls', N'cars';


PRINT N'--- Đang nạp Unit 8: Fantastic Holidays ---';
EXEC #AddQuiz N'Unit 8', N'Could you show me the way to the ______?', N'market', N'mark', N'marketing', N'marked';
EXEC #AddQuiz N'Unit 8', N'Go ______ and turn left.', N'straight', N'street', N'long', N'short';
EXEC #AddQuiz N'Unit 8', N'It is on your ______.', N'right', N'write', N'white', N'light';
EXEC #AddQuiz N'Unit 8', N'The Mid-Autumn Festival is next ______.', N'week', N'day', N'month', N'year';
EXEC #AddQuiz N'Unit 8', N'What ______ you do there?', N'will', N'do', N'did', N'does';
EXEC #AddQuiz N'Unit 8', N'I will ______ lanterns.', N'light', N'see', N'watch', N'look';
EXEC #AddQuiz N'Unit 8', N'We will watch a ______ dance.', N'lion', N'tiger', N'cat', N'dog';
EXEC #AddQuiz N'Unit 8', N'I will go to my grandma''s ______.', N'house', N'home', N'school', N'work';
EXEC #AddQuiz N'Unit 8', N'We will eat lots of ______.', N'mooncakes', N'pizza', N'burgers', N'rice';
EXEC #AddQuiz N'Unit 8', N'I will wear a ______ for Halloween.', N'costume', N'uniform', N'dress', N'shirt';
EXEC #AddQuiz N'Unit 8', N'We will visit a ______ park.', N'theme', N'team', N'time', N'term';
EXEC #AddQuiz N'Unit 8', N'I am going to buy ______.', N'souvenirs', N'gifts', N'presents', N'toys';
EXEC #AddQuiz N'Unit 8', N'Where is the ______?', N'waterfall', N'water', N'falling', N'fell';
EXEC #AddQuiz N'Unit 8', N'We will stay at a ______.', N'resort', N'hotel', N'home', N'house';
EXEC #AddQuiz N'Unit 8', N'Children get ______ money at Tet.', N'lucky', N'happy', N'good', N'bad';
EXEC #AddQuiz N'Unit 8', N'We clean our house ______ Tet.', N'before', N'after', N'during', N'when';
EXEC #AddQuiz N'Unit 8', N'Do you like Christmas?', N'Yes, I do.', N'Yes, I am.', N'No, I am not.', N'Yes, it is.';
EXEC #AddQuiz N'Unit 8', N'We will have a ______ time.', N'great', N'bad', N'sad', N'boring';
EXEC #AddQuiz N'Unit 8', N'Turn right at the ______ shop.', N'souvenir', N'book', N'food', N'clothes';
EXEC #AddQuiz N'Unit 8', N'I am excited ______ the holidays.', N'for', N'with', N'at', N'in';

-- XÓA THỦ TỤC TẠM
DROP PROCEDURE #AddQuiz;

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU TRẮC NGHIỆM (20 CÂU x 9 UNIT)!';
GO

USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO DỮ LIỆU ROUND 4 (ĐIỀN TỪ) ===';

-- 1. DỌN DẸP DỮ LIỆU CŨ
DELETE FROM QuestionOptions WHERE QuestionID IN (SELECT QuestionID FROM Questions WHERE QuestionType = 'fill_in_blank');
DELETE FROM Questions WHERE QuestionType = 'fill_in_blank';
PRINT N'🧹 Đã dọn dẹp dữ liệu cũ.';

-- 2. TẠO THỦ TỤC TẠM
IF OBJECT_ID('tempdb..#AddFillBlank') IS NOT NULL DROP PROCEDURE #AddFillBlank;
GO

CREATE PROCEDURE #AddFillBlank
    @UnitName NVARCHAR(100),
    @Sentence NVARCHAR(MAX),   -- Câu hỏi có chứa '______'
    @CorrectAns NVARCHAR(255), -- Từ đúng để điền
    @Wrong1 NVARCHAR(255),     -- Từ sai 1
    @Wrong2 NVARCHAR(255),     -- Từ sai 2
    @Wrong3 NVARCHAR(255)      -- Từ sai 3
AS
BEGIN
    DECLARE @TopicID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE @UnitName + N'%');
    DECLARE @QID INT;

    IF @TopicID IS NOT NULL
    BEGIN
        -- Chèn câu hỏi
        INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
        VALUES (@TopicID, @Sentence, 'fill_in_blank', @CorrectAns);
        
        SET @QID = SCOPE_IDENTITY();

        -- Chèn đáp án (Frontend có thể dùng để làm gợi ý hoặc trắc nghiệm điền từ)
        INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
        (@QID, @CorrectAns, 1),
        (@QID, @Wrong1, 0),
        (@QID, @Wrong2, 0),
        (@QID, @Wrong3, 0);
    END
END;
GO

-- ======================================================================================
-- 3. NẠP DỮ LIỆU (20 CÂU/UNIT)
-- ======================================================================================

PRINT N'--- Unit 0: Getting Started ---';
EXEC #AddFillBlank N'Unit 0', N'The weather is hot in ______.', N'summer', N'winter', N'spring', N'fall';
EXEC #AddFillBlank N'Unit 0', N'Leaves fall from trees in ______.', N'autumn', N'summer', N'spring', N'winter';
EXEC #AddFillBlank N'Unit 0', N'It is ______ and snowy in winter.', N'cold', N'hot', N'warm', N'dry';
EXEC #AddFillBlank N'Unit 0', N'There are twelve ______ in a year.', N'months', N'weeks', N'days', N'seasons';
EXEC #AddFillBlank N'Unit 0', N'My birthday is ______ May.', N'in', N'on', N'at', N'of';
EXEC #AddFillBlank N'Unit 0', N'What is the weather ______ today?', N'like', N'is', N'look', N'love';
EXEC #AddFillBlank N'Unit 0', N'Ten plus ten is ______.', N'twenty', N'thirty', N'ten', N'forty';
EXEC #AddFillBlank N'Unit 0', N'I like to go swimming in the ______ season.', N'dry', N'rainy', N'cold', N'snowy';
EXEC #AddFillBlank N'Unit 0', N'We wear coats when it is ______.', N'cold', N'hot', N'sunny', N'warm';
EXEC #AddFillBlank N'Unit 0', N'______ is the first month.', N'January', N'February', N'December', N'March';
EXEC #AddFillBlank N'Unit 0', N'Flowers bloom in ______.', N'spring', N'winter', N'autumn', N'night';
EXEC #AddFillBlank N'Unit 0', N'One hundred ______ fifty is fifty.', N'minus', N'plus', N'times', N'and';
EXEC #AddFillBlank N'Unit 0', N'Is your birthday in June? - No, it ______.', N'isn''t', N'is', N'not', N'aren''t';
EXEC #AddFillBlank N'Unit 0', N'Do you like sunny weather? - Yes, I ______.', N'do', N'am', N'don''t', N'does';
EXEC #AddFillBlank N'Unit 0', N'The ______ season has a lot of rain.', N'rainy', N'dry', N'hot', N'cold';
EXEC #AddFillBlank N'Unit 0', N'March, April, and May are in ______.', N'spring', N'summer', N'winter', N'fall';
EXEC #AddFillBlank N'Unit 0', N'It is usually ______ in the desert.', N'hot', N'cold', N'wet', N'snowy';
EXEC #AddFillBlank N'Unit 0', N'______ comes after August.', N'September', N'July', N'October', N'June';
EXEC #AddFillBlank N'Unit 0', N'Twenty plus ______ is thirty.', N'ten', N'five', N'twenty', N'one';
EXEC #AddFillBlank N'Unit 0', N'I make a snowman in ______.', N'winter', N'summer', N'fall', N'spring';

PRINT N'--- Unit 1: Animal Habitats ---';
EXEC #AddFillBlank N'Unit 1', N'A camel lives in the ______.', N'desert', N'sea', N'forest', N'cave';
EXEC #AddFillBlank N'Unit 1', N'Polar bears live in the ______ region.', N'polar', N'hot', N'rainy', N'dry';
EXEC #AddFillBlank N'Unit 1', N'Fish swim in the ______.', N'water', N'sky', N'sand', N'tree';
EXEC #AddFillBlank N'Unit 1', N'Birds build ______ in trees.', N'nests', N'caves', N'hives', N'holes';
EXEC #AddFillBlank N'Unit 1', N'Bees live in a ______.', N'hive', N'nest', N'cave', N'house';
EXEC #AddFillBlank N'Unit 1', N'A giraffe has a long ______.', N'neck', N'nose', N'ear', N'hand';
EXEC #AddFillBlank N'Unit 1', N'Elephants use their ______ to drink water.', N'trunks', N'ears', N'tails', N'legs';
EXEC #AddFillBlank N'Unit 1', N'A kangaroo has a ______ for its baby.', N'pouch', N'bag', N'box', N'pocket';
EXEC #AddFillBlank N'Unit 1', N'Monkeys can ______ trees.', N'climb', N'fly', N'swim', N'run';
EXEC #AddFillBlank N'Unit 1', N'Penguins cannot ______.', N'fly', N'swim', N'walk', N'jump';
EXEC #AddFillBlank N'Unit 1', N'Bats sleep in ______ during the day.', N'caves', N'nests', N'hives', N'water';
EXEC #AddFillBlank N'Unit 1', N'Crocodiles have sharp ______.', N'teeth', N'hair', N'ears', N'hands';
EXEC #AddFillBlank N'Unit 1', N'The ocean is very ______.', N'deep', N'high', N'tall', N'dry';
EXEC #AddFillBlank N'Unit 1', N'Tigers have ______ on their bodies.', N'stripes', N'spots', N'dots', N'squares';
EXEC #AddFillBlank N'Unit 1', N'A ______ moves very slowly.', N'turtle', N'rabbit', N'cat', N'dog';
EXEC #AddFillBlank N'Unit 1', N'Hippos like to play in the ______.', N'mud', N'sky', N'tree', N'bed';
EXEC #AddFillBlank N'Unit 1', N'Birds have wings and ______.', N'feathers', N'fur', N'scales', N'skin';
EXEC #AddFillBlank N'Unit 1', N'Goats have two ______ on their heads.', N'horns', N'tails', N'noses', N'wings';
EXEC #AddFillBlank N'Unit 1', N'We must ______ the animals.', N'protect', N'hurt', N'hit', N'scare';
EXEC #AddFillBlank N'Unit 1', N'Sharks live in the ______.', N'ocean', N'river', N'pond', N'pool';

PRINT N'--- Unit 2: Let''s Eat! ---';
EXEC #AddFillBlank N'Unit 2', N'I would like a ______ of noodles.', N'bowl', N'box', N'bag', N'book';
EXEC #AddFillBlank N'Unit 2', N'Can I have a ______ of water?', N'bottle', N'piece', N'loaf', N'slice';
EXEC #AddFillBlank N'Unit 2', N'This lemon tastes ______.', N'sour', N'sweet', N'spicy', N'salty';
EXEC #AddFillBlank N'Unit 2', N'Chili peppers are very ______.', N'spicy', N'sweet', N'cold', N'bitter';
EXEC #AddFillBlank N'Unit 2', N'I want a ______ of cereal.', N'box', N'bottle', N'can', N'tube';
EXEC #AddFillBlank N'Unit 2', N'Would you like ______ beans?', N'some', N'a', N'an', N'one';
EXEC #AddFillBlank N'Unit 2', N'Is there ______ milk in the fridge?', N'any', N'many', N'a', N'some';
EXEC #AddFillBlank N'Unit 2', N'No, there aren''t ______ eggs.', N'any', N'some', N'much', N'little';
EXEC #AddFillBlank N'Unit 2', N'Potato chips are usually ______.', N'salty', N'sweet', N'sour', N'bitter';
EXEC #AddFillBlank N'Unit 2', N'Candy and chocolate are ______.', N'sweet', N'spicy', N'sour', N'salty';
EXEC #AddFillBlank N'Unit 2', N'May I have a ______ of pizza?', N'slice', N'bowl', N'bottle', N'jar';
EXEC #AddFillBlank N'Unit 2', N'A ______ of bread.', N'loaf', N'can', N'box', N'bottle';
EXEC #AddFillBlank N'Unit 2', N'I am hungry. I want to ______.', N'eat', N'drink', N'sleep', N'run';
EXEC #AddFillBlank N'Unit 2', N'I am thirsty. I need ______.', N'water', N'food', N'bread', N'meat';
EXEC #AddFillBlank N'Unit 2', N'Can you pass me the ______?', N'salt', N'rain', N'wind', N'sun';
EXEC #AddFillBlank N'Unit 2', N'Do not eat too much ______.', N'sugar', N'water', N'vegetable', N'fruit';
EXEC #AddFillBlank N'Unit 2', N'Coffee without milk is ______.', N'bitter', N'sweet', N'salty', N'sour';
EXEC #AddFillBlank N'Unit 2', N'My favorite food is ______.', N'chicken', N'water', N'juice', N'milk';
EXEC #AddFillBlank N'Unit 2', N'We need a ______ of oil.', N'bottle', N'box', N'bag', N'basket';
EXEC #AddFillBlank N'Unit 2', N'Let''s make a ______.', N'cake', N'water', N'milk', N'juice';

PRINT N'--- Unit 3: On the Move! ---';
EXEC #AddFillBlank N'Unit 3', N'I go to school ______ bus.', N'by', N'on', N'in', N'at';
EXEC #AddFillBlank N'Unit 3', N'We walk on the ______.', N'sidewalk', N'street', N'road', N'river';
EXEC #AddFillBlank N'Unit 3', N'My father ______ a car to work.', N'drives', N'rides', N'flies', N'walks';
EXEC #AddFillBlank N'Unit 3', N'I ______ my bicycle in the park.', N'ride', N'drive', N'run', N'fly';
EXEC #AddFillBlank N'Unit 3', N'A ______ flies in the sky.', N'plane', N'bus', N'train', N'boat';
EXEC #AddFillBlank N'Unit 3', N'The ______ runs on tracks.', N'train', N'car', N'bus', N'taxi';
EXEC #AddFillBlank N'Unit 3', N'We took a ______ across the river.', N'ferry', N'bike', N'scooter', N'truck';
EXEC #AddFillBlank N'Unit 3', N'You must ______ at the red light.', N'stop', N'go', N'run', N'walk';
EXEC #AddFillBlank N'Unit 3', N'Always wear a ______ on a motorbike.', N'helmet', N'hat', N'cap', N'mask';
EXEC #AddFillBlank N'Unit 3', N'The subway goes ______ ground.', N'under', N'on', N'above', N'in';
EXEC #AddFillBlank N'Unit 3', N'We get ______ the bus at the station.', N'off', N'out', N'away', N'over';
EXEC #AddFillBlank N'Unit 3', N'How ______ do you ride your bike?', N'often', N'many', N'much', N'time';
EXEC #AddFillBlank N'Unit 3', N'I go to school on ______.', N'foot', N'leg', N'hand', N'head';
EXEC #AddFillBlank N'Unit 3', N'Boats ______ on water.', N'sail', N'drive', N'ride', N'run';
EXEC #AddFillBlank N'Unit 3', N'A helicopter has ______ on top.', N'blades', N'wings', N'wheels', N'doors';
EXEC #AddFillBlank N'Unit 3', N'Is it safe? - Yes, it ______.', N'is', N'isn''t', N'does', N'do';
EXEC #AddFillBlank N'Unit 3', N'Traffic lights have ______ colors.', N'three', N'two', N'four', N'five';
EXEC #AddFillBlank N'Unit 3', N'Green light means ______.', N'go', N'stop', N'wait', N'slow';
EXEC #AddFillBlank N'Unit 3', N'I sit ______ the car.', N'in', N'on', N'at', N'under';
EXEC #AddFillBlank N'Unit 3', N'He goes to work ______ motorcycle.', N'by', N'in', N'with', N'at';

PRINT N'--- Unit 4: Our Senses ---';
EXEC #AddFillBlank N'Unit 4', N'I use my ______ to see.', N'eyes', N'ears', N'nose', N'mouth';
EXEC #AddFillBlank N'Unit 4', N'I use my ______ to hear.', N'ears', N'eyes', N'hands', N'legs';
EXEC #AddFillBlank N'Unit 4', N'I use my nose to ______.', N'smell', N'taste', N'touch', N'look';
EXEC #AddFillBlank N'Unit 4', N'The rabbit feels ______.', N'soft', N'hard', N'loud', N'quiet';
EXEC #AddFillBlank N'Unit 4', N'The rock feels ______.', N'hard', N'soft', N'sweet', N'sour';
EXEC #AddFillBlank N'Unit 4', N'The music is too ______.', N'loud', N'soft', N'tasty', N'smelly';
EXEC #AddFillBlank N'Unit 4', N'The flowers look ______.', N'beautiful', N'ugly', N'loud', N'quiet';
EXEC #AddFillBlank N'Unit 4', N'The garbage smells ______.', N'bad', N'good', N'nice', N'sweet';
EXEC #AddFillBlank N'Unit 4', N'The lemon tastes ______.', N'sour', N'salty', N'spicy', N'hot';
EXEC #AddFillBlank N'Unit 4', N'Did you ______ the thunder?', N'hear', N'smell', N'touch', N'taste';
EXEC #AddFillBlank N'Unit 4', N'The rainbow looks ______.', N'colorful', N'loud', N'bad', N'tasty';
EXEC #AddFillBlank N'Unit 4', N'Smoke smells like ______ wood.', N'burnt', N'fresh', N'clean', N'sweet';
EXEC #AddFillBlank N'Unit 4', N'Durian has a strong ______.', N'smell', N'sound', N'look', N'touch';
EXEC #AddFillBlank N'Unit 4', N'Please be ______ in the library.', N'quiet', N'loud', N'noisy', N'fast';
EXEC #AddFillBlank N'Unit 4', N'I touch with my ______.', N'hands', N'eyes', N'ears', N'nose';
EXEC #AddFillBlank N'Unit 4', N'The drum sounds ______.', N'loud', N'soft', N'quiet', N'bad';
EXEC #AddFillBlank N'Unit 4', N'Does it taste good? - Yes, it ______.', N'does', N'is', N'do', N'are';
EXEC #AddFillBlank N'Unit 4', N'The pillow is ______.', N'soft', N'hard', N'sharp', N'loud';
EXEC #AddFillBlank N'Unit 4', N'Look ______ the beautiful picture.', N'at', N'in', N'on', N'for';
EXEC #AddFillBlank N'Unit 4', N'Blind people cannot ______.', N'see', N'hear', N'smell', N'touch';

PRINT N'--- Unit 5: Our Health ---';
EXEC #AddFillBlank N'Unit 5', N'What is the ______ with you?', N'matter', N'wrong', N'problem', N'bad';
EXEC #AddFillBlank N'Unit 5', N'I have a ______.', N'headache', N'head', N'happy', N'hungry';
EXEC #AddFillBlank N'Unit 5', N'You should see a ______.', N'doctor', N'teacher', N'farmer', N'driver';
EXEC #AddFillBlank N'Unit 5', N'He has a sore ______.', N'throat', N'hand', N'hair', N'shoe';
EXEC #AddFillBlank N'Unit 5', N'You should ______ some medicine.', N'take', N'eat', N'drink', N'do';
EXEC #AddFillBlank N'Unit 5', N'She has a high ______.', N'fever', N'heat', N'hot', N'cold';
EXEC #AddFillBlank N'Unit 5', N'I have a ______ nose.', N'runny', N'running', N'rainy', N'sunny';
EXEC #AddFillBlank N'Unit 5', N'You should ______ your hands.', N'wash', N'watch', N'play', N'eat';
EXEC #AddFillBlank N'Unit 5', N'Don''t eat too much ______.', N'candy', N'water', N'vegetable', N'rice';
EXEC #AddFillBlank N'Unit 5', N'You should ______ in bed.', N'rest', N'run', N'jump', N'dance';
EXEC #AddFillBlank N'Unit 5', N'My tooth hurts. I have a ______.', N'toothache', N'headache', N'backache', N'earache';
EXEC #AddFillBlank N'Unit 5', N'Drink plenty of ______.', N'water', N'soda', N'coffee', N'tea';
EXEC #AddFillBlank N'Unit 5', N'Exercise is ______ for you.', N'good', N'bad', N'sad', N'sick';
EXEC #AddFillBlank N'Unit 5', N'I ______ feel well.', N'don''t', N'not', N'am', N'isn''t';
EXEC #AddFillBlank N'Unit 5', N'Did you ______ the medicine?', N'take', N'eat', N'drink', N'go';
EXEC #AddFillBlank N'Unit 5', N'I have a stomachache. My ______ hurts.', N'stomach', N'head', N'leg', N'arm';
EXEC #AddFillBlank N'Unit 5', N'You look ______.', N'tired', N'tire', N'tiring', N'sleep';
EXEC #AddFillBlank N'Unit 5', N'You shouldn''t stay up ______.', N'late', N'early', N'morning', N'noon';
EXEC #AddFillBlank N'Unit 5', N'Cover your mouth when you ______.', N'cough', N'laugh', N'smile', N'eat';
EXEC #AddFillBlank N'Unit 5', N'Healthy food makes us ______.', N'strong', N'weak', N'sick', N'tired';

PRINT N'--- Unit 6: The World of School ---';
EXEC #AddFillBlank N'Unit 6', N'We read books in the ______.', N'library', N'gym', N'canteen', N'pool';
EXEC #AddFillBlank N'Unit 6', N'I have math ______ Monday.', N'on', N'in', N'at', N'of';
EXEC #AddFillBlank N'Unit 6', N'My favorite subject is ______.', N'English', N'football', N'game', N'sleep';
EXEC #AddFillBlank N'Unit 6', N'We play sports in the ______.', N'gym', N'library', N'class', N'lab';
EXEC #AddFillBlank N'Unit 6', N'I went to the ______ yesterday.', N'zoo', N'go', N'goes', N'going';
EXEC #AddFillBlank N'Unit 6', N'Did you ______ a video?', N'make', N'do', N'play', N'go';
EXEC #AddFillBlank N'Unit 6', N'I use a ______ in IT class.', N'computer', N'ball', N'book', N'pen';
EXEC #AddFillBlank N'Unit 6', N'We learn about the past in ______.', N'history', N'math', N'music', N'art';
EXEC #AddFillBlank N'Unit 6', N'I draw pictures in ______ class.', N'art', N'math', N'PE', N'IT';
EXEC #AddFillBlank N'Unit 6', N'Our school has a big ______.', N'playground', N'play', N'playing', N'played';
EXEC #AddFillBlank N'Unit 6', N'My teacher is very ______.', N'kind', N'bad', N'angry', N'sad';
EXEC #AddFillBlank N'Unit 6', N'We wear a ______ at school.', N'uniform', N'costume', N'pyjama', N'hat';
EXEC #AddFillBlank N'Unit 6', N'I joined a science ______.', N'club', N'class', N'room', N'house';
EXEC #AddFillBlank N'Unit 6', N'What ______ do you have today?', N'subjects', N'games', N'toys', N'food';
EXEC #AddFillBlank N'Unit 6', N'I like to ______ the piano.', N'play', N'do', N'make', N'go';
EXEC #AddFillBlank N'Unit 6', N'We eat lunch in the ______.', N'canteen', N'library', N'gym', N'lab';
EXEC #AddFillBlank N'Unit 6', N'I do my ______ after school.', N'homework', N'housework', N'play', N'sleep';
EXEC #AddFillBlank N'Unit 6', N'Did you go to school? - Yes, I ______.', N'did', N'do', N'does', N'done';
EXEC #AddFillBlank N'Unit 6', N'We learn to sing in ______ class.', N'music', N'math', N'art', N'PE';
EXEC #AddFillBlank N'Unit 6', N'The school year starts in ______.', N'September', N'July', N'May', N'January';

PRINT N'--- Unit 7: The World of Work ---';
EXEC #AddFillBlank N'Unit 7', N'A ______ teaches students.', N'teacher', N'doctor', N'farmer', N'driver';
EXEC #AddFillBlank N'Unit 7', N'A doctor works in a ______.', N'hospital', N'school', N'farm', N'shop';
EXEC #AddFillBlank N'Unit 7', N'A ______ flies a plane.', N'pilot', N'driver', N'rider', N'worker';
EXEC #AddFillBlank N'Unit 7', N'What do you want to ______?', N'be', N'do', N'make', N'have';
EXEC #AddFillBlank N'Unit 7', N'I want to be a ______.', N'singer', N'sing', N'song', N'singing';
EXEC #AddFillBlank N'Unit 7', N'A farmer grows ______.', N'vegetables', N'cars', N'houses', N'clothes';
EXEC #AddFillBlank N'Unit 7', N'A ______ puts out fires.', N'firefighter', N'teacher', N'doctor', N'cook';
EXEC #AddFillBlank N'Unit 7', N'A chef ______ food.', N'cooks', N'eats', N'buys', N'sells';
EXEC #AddFillBlank N'Unit 7', N'A ______ builds houses.', N'builder', N'teacher', N'nurse', N'artist';
EXEC #AddFillBlank N'Unit 7', N'An artist paints ______.', N'pictures', N'walls', N'cars', N'floors';
EXEC #AddFillBlank N'Unit 7', N'A vet helps sick ______.', N'animals', N'people', N'cars', N'computers';
EXEC #AddFillBlank N'Unit 7', N'A dentist fixes ______.', N'teeth', N'hair', N'eyes', N'ears';
EXEC #AddFillBlank N'Unit 7', N'A police officer ______ us safe.', N'keeps', N'makes', N'does', N'has';
EXEC #AddFillBlank N'Unit 7', N'He works very ______.', N'hard', N'bad', N'lazy', N'slow';
EXEC #AddFillBlank N'Unit 7', N'A salesperson works in a ______.', N'shop', N'school', N'hospital', N'farm';
EXEC #AddFillBlank N'Unit 7', N'I want to ______ people.', N'help', N'hurt', N'hit', N'sad';
EXEC #AddFillBlank N'Unit 7', N'A mechanic fixes ______.', N'cars', N'teeth', N'people', N'food';
EXEC #AddFillBlank N'Unit 7', N'A baker makes ______.', N'bread', N'meat', N'fruit', N'soup';
EXEC #AddFillBlank N'Unit 7', N'What does your father ______?', N'do', N'be', N'make', N'work';
EXEC #AddFillBlank N'Unit 7', N'She wants to be a famous ______.', N'singer', N'sing', N'sang', N'song';

PRINT N'--- Unit 8: Fantastic Holidays ---';
EXEC #AddFillBlank N'Unit 8', N'We will go to the ______.', N'beach', N'school', N'work', N'hospital';
EXEC #AddFillBlank N'Unit 8', N'I will ______ my grandma.', N'visit', N'see', N'watch', N'look';
EXEC #AddFillBlank N'Unit 8', N'We eat ______ cake at Mid-Autumn.', N'moon', N'sun', N'star', N'sky';
EXEC #AddFillBlank N'Unit 8', N'Children get lucky ______ at Tet.', N'money', N'candy', N'toy', N'book';
EXEC #AddFillBlank N'Unit 8', N'We will stay at a ______.', N'hotel', N'school', N'shop', N'park';
EXEC #AddFillBlank N'Unit 8', N'Go ______ and turn left.', N'straight', N'street', N'right', N'back';
EXEC #AddFillBlank N'Unit 8', N'The market is on your ______.', N'right', N'write', N'white', N'light';
EXEC #AddFillBlank N'Unit 8', N'I will buy some ______.', N'souvenirs', N'money', N'hotel', N'beach';
EXEC #AddFillBlank N'Unit 8', N'We decorate the house ______ Tet.', N'before', N'after', N'during', N'when';
EXEC #AddFillBlank N'Unit 8', N'Santa Claus comes at ______.', N'Christmas', N'Tet', N'Easter', N'Halloween';
EXEC #AddFillBlank N'Unit 8', N'We watch a ______ dance.', N'lion', N'tiger', N'cat', N'dog';
EXEC #AddFillBlank N'Unit 8', N'I will ______ a sandcastle.', N'build', N'make', N'do', N'go';
EXEC #AddFillBlank N'Unit 8', N'Where ______ you go?', N'will', N'do', N'did', N'does';
EXEC #AddFillBlank N'Unit 8', N'It will be ______.', N'fun', N'sad', N'bad', N'boring';
EXEC #AddFillBlank N'Unit 8', N'I wear a ______ for Halloween.', N'costume', N'uniform', N'suit', N'dress';
EXEC #AddFillBlank N'Unit 8', N'We will swim in the ______.', N'sea', N'sky', N'sand', N'mountain';
EXEC #AddFillBlank N'Unit 8', N'Happy New ______!', N'Year', N'Day', N'Month', N'Week';
EXEC #AddFillBlank N'Unit 8', N'I am going to ______ a trip.', N'take', N'do', N'make', N'go';
EXEC #AddFillBlank N'Unit 8', N'See you ______ week.', N'next', N'last', N'past', N'before';
EXEC #AddFillBlank N'Unit 8', N'We travel by ______.', N'plane', N'foot', N'walk', N'run';

-- XÓA THỦ TỤC
DROP PROCEDURE #AddFillBlank;

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU ĐIỀN TỪ (20 CÂU x 9 UNIT)!';
GO

USE GameHocTiengAnh1; -- Đổi tên DB nếu của bạn khác
GO

-- Xem toàn bộ lịch sử chơi
SELECT * FROM PlayHistory ORDER BY PlayedAt DESC;

-- Kiểm tra xem User hiện tại có đủ điểm 4 vòng chưa (Thay ID = 1 bằng ID của bạn nếu cần)
SELECT StudentID, GameID, MAX(Score) as MaxScore 
FROM PlayHistory 
GROUP BY StudentID, GameID
ORDER BY GameID;

-- ==========================================================
-- BỔ SUNG: TẠO DỮ LIỆU CÁC MÀN CHƠI (GAMES)
-- Bắt buộc phải chạy đoạn này để có GameID 1, 2, 3, 4
-- ==========================================================
INSERT INTO Games (GameName, GameDescription, TimeLimit, PassScore)
VALUES 
(N'Round 1: Matching', N'Nối từ vựng và nghĩa', 0, 5),       -- Sẽ tự động có GameID = 1
(N'Round 2: Scramble', N'Sắp xếp lại câu', 0, 5),            -- Sẽ tự động có GameID = 2
(N'Round 3: Multiple Choice', N'Trắc nghiệm ABCD', 0, 5),    -- Sẽ tự động có GameID = 3
(N'Round 4: Fill in Blank', N'Điền từ vào chỗ trống', 0, 5); -- Sẽ tự động có GameID = 4
GO

PRINT N'✅ Đã tạo xong 4 Game Round (ID 1-4).';

-- Xóa bảng cũ
-- 1. Xóa ràng buộc kiểm tra giá trị của Stars (CK_Stars_Range)
ALTER TABLE PlayHistory 
DROP CONSTRAINT CK_Stars_Range;

-- 2. Xóa cột Stars
ALTER TABLE PlayHistory 
DROP COLUMN Stars;

-- 3. Thêm cột Difficulty (Độ khó)
-- Dùng NVARCHAR(50) để lưu được tiếng Việt hoặc tiếng Anh (Easy, Normal, Hard)
ALTER TABLE PlayHistory 
ADD Difficulty NVARCHAR(50);