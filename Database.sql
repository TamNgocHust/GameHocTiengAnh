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

--Chèn chủ đề cho từ vựng và bài tập 
INSERT INTO Topics (TopicName) VALUES 
    (N'Unit 1: All about me! (Tất cả về tôi)'),
    (N'Unit 2: Our homes (Ngôi nhà của chúng ta)'),
    (N'Unit 3: My foreign friends (Những người bạn nước ngoài)'),
    (N'Unit 4: Our free-time activities (Hoạt động giải trí)'),
    (N'Unit 5: My future job (Nghề nghiệp tương lai)'),
    (N'Unit 6: Our school rooms (Phòng học của chúng ta)'),
    (N'Unit 7: Our favourite school activities (Hoạt động ở trường)'),
    (N'Unit 8: In our classroom (Trong lớp học)'),
    (N'Unit 9: Our outdoor activities (Hoạt động ngoài trời)'),
    (N'Unit 10: Our school trip (Chuyến đi dã ngoại)'),
    (N'Unit 11: Family time (Thời gian cho gia đình)'),
    (N'Unit 12: Our Tet Holiday (Ngày Tết của chúng ta)'),
    (N'Unit 13: Our special days (Những ngày đặc biệt)'),
    (N'Unit 14: Staying healthy (Sống khỏe mạnh)'),
    (N'Unit 15: Our health (Sức khỏe của chúng ta)'),
    (N'Unit 16: Seasons and the weather (Mùa và thời tiết)'),
    (N'Unit 17: Stories for children (Truyện kể cho bé)'),
    (N'Unit 18: Means of transport (Phương tiện giao thông)'),
    (N'Unit 19: Places of interest (Danh lam thắng cảnh)'),
    (N'Unit 20: Our summer holidays (Kỳ nghỉ hè của chúng ta)');
GO

--Chèn dữ liệu vào bảng Vocab
DECLARE @CurrentTopicID INT;
-- Bước 1: Lấy ID tự động của Unit 1
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 1%';
-- Bước 2: Kiểm tra và chèn dữ liệu
IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('family', N'/ˈfæmɪli/', N'gia đình', 'Noun', N'I love my family.', @CurrentTopicID, NULL, NULL),
    ('friend', N'/frend/', N'bạn bè', 'Noun', N'She is my best friend.', @CurrentTopicID, NULL, NULL),
    ('school', N'/skuːl/', N'trường học', 'Noun', N'I go to school by bus.', @CurrentTopicID, NULL, NULL),
    ('classmate', N'/ˈklɑːsmeɪt/', N'bạn cùng lớp', 'Noun', N'He is my new classmate.', @CurrentTopicID, NULL, NULL),
    ('hobby', N'/ˈhɒbi/', N'sở thích', 'Noun', N'My hobby is reading books.', @CurrentTopicID, NULL, NULL),
    ('active', N'/ˈæktɪv/', N'năng động', 'Adjective', N'Tom is very active.', @CurrentTopicID, NULL, NULL),
    ('clever', N'/ˈklevə/', N'thông minh', 'Adjective', N'She is a clever student.', @CurrentTopicID, NULL, NULL),
    ('friendly', N'/ˈfrendli/', N'thân thiện', 'Adjective', N'Our teacher is very friendly.', @CurrentTopicID, NULL, NULL),
    ('helpful', N'/ˈhelpfʊl/', N'hữu ích, hay giúp đỡ', 'Adjective', N'Thank you for being helpful.', @CurrentTopicID, NULL, NULL),
    ('kind', N'/kaɪnd/', N'tử tế, tốt bụng', 'Adjective', N'Be kind to others.', @CurrentTopicID, NULL, NULL),
    ('like', N'/laɪk/', N'thích', 'Verb', N'I like ice cream.', @CurrentTopicID, NULL, NULL),
    ('play', N'/pleɪ/', N'chơi', 'Verb', N'Let''s play football.', @CurrentTopicID, NULL, NULL),
    ('talk', N'/tɔːk/', N'nói chuyện', 'Verb', N'Please do not talk in class.', @CurrentTopicID, NULL, NULL),
    ('share', N'/ʃeə/', N'chia sẻ', 'Verb', N'Share your toys with friends.', @CurrentTopicID, NULL, NULL),
    ('learn', N'/lɜːn/', N'học hỏi', 'Verb', N'We learn English together.', @CurrentTopicID, NULL, NULL);
END
ELSE
BEGIN
    PRINT N'Lỗi: Không tìm thấy Topic Unit 1. Vui lòng kiểm tra lại bảng Topics.';
END
GO
DECLARE @CurrentTopicID INT;

-- ==========================================================
-- UNIT 2: Our homes (Ngôi nhà của chúng ta)
-- ==========================================================
-- Bước 1: Lấy ID tự động của Unit 2
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 2%';

-- Bước 2: Kiểm tra và chèn dữ liệu
IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('flat', N'/flæt/', N'căn hộ', 'Noun', N'My flat is small but cozy.', @CurrentTopicID, NULL, NULL),
    ('address', N'/ə''dres/', N'địa chỉ', 'Noun', N'What is your address?', @CurrentTopicID, NULL, NULL),
    ('building', N'/''bɪldɪŋ/', N'tòa nhà', 'Noun', N'It is a very tall building.', @CurrentTopicID, NULL, NULL),
    ('tower', N'/''taʊə(r)/', N'tòa tháp', 'Noun', N'He lives in Tower B.', @CurrentTopicID, NULL, NULL),
    ('district', N'/''dɪstrɪkt/', N'quận', 'Noun', N'I live in Cau Giay District.', @CurrentTopicID, NULL, NULL),
    ('comfortable', N'/''kʌmfətəbl/', N'thoải mái', 'Adjective', N'This sofa is very comfortable.', @CurrentTopicID, NULL, NULL),
    ('clean', N'/kli:n/', N'sạch sẽ', 'Adjective', N'Keep your room clean.', @CurrentTopicID, NULL, NULL),
    ('tidy', N'/''taɪdi/', N'ngăn nắp', 'Adjective', N'Her desk is always tidy.', @CurrentTopicID, NULL, NULL),
    ('messy', N'/''mesi/', N'bừa bộn', 'Adjective', N'Do not leave your room messy.', @CurrentTopicID, NULL, NULL),
    ('far', N'/fɑ:(r)/', N'xa', 'Adjective', N'Is your school far from here?', @CurrentTopicID, NULL, NULL),
    ('near', N'/nɪə(r)/', N'gần', 'Adjective', N'My house is near the park.', @CurrentTopicID, NULL, NULL),
    ('live', N'/lɪv/', N'sống', 'Verb', N'I live in Hanoi.', @CurrentTopicID, NULL, NULL),
    ('hometown', N'/''həʊmtaʊn/', N'quê hương', 'Noun', N'My hometown is Da Nang.', @CurrentTopicID, NULL, NULL); -- Bổ sung thêm từ này thường đi kèm chủ đề

    PRINT N'Đã thêm thành công 13 từ vựng vào Unit 2.';
END
ELSE
BEGIN
    PRINT N'Lỗi: Không tìm thấy Topic Unit 2. Vui lòng kiểm tra lại bảng Topics.';
END
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 3
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 3%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('Vietnamese', N'/ˌvjɛtnəˈmiːz/', N'người Việt Nam', 'Noun, Adjective', N'I am Vietnamese.', @CurrentTopicID, NULL, NULL),
    ('American', N'/əˈmɛrɪkən/', N'người Mỹ', 'Noun, Adjective', N'He is American.', @CurrentTopicID, NULL, NULL),
    ('Japanese', N'/ˌdʒæpəˈniːz/', N'người Nhật Bản', 'Noun, Adjective', N'She is Japanese.', @CurrentTopicID, NULL, NULL),
    ('Australian', N'/ɒˈstreɪliən/', N'người Úc', 'Noun, Adjective', N'Tony is Australian.', @CurrentTopicID, NULL, NULL),
    ('Malaysian', N'/məˈleɪʒn/', N'người Malaysia', 'Noun, Adjective', N'Hakim is Malaysian.', @CurrentTopicID, NULL, NULL),
    ('active', N'/ˈæktɪv/', N'năng động', 'Adjective', N'He is very active.', @CurrentTopicID, NULL, NULL),
    ('clever', N'/ˈklɛvə/', N'thông minh', 'Adjective', N'She is a clever girl.', @CurrentTopicID, NULL, NULL),
    ('friendly', N'/ˈfrɛndli/', N'thân thiện', 'Adjective', N'Everyone is friendly.', @CurrentTopicID, NULL, NULL),
    ('kind', N'/kaɪnd/', N'tử tế', 'Adjective', N'Be kind to your friends.', @CurrentTopicID, NULL, NULL),
    ('talk', N'/tɔːk/', N'nói chuyện', 'Verb', N'We talk every day.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 3.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 3.';
GO
DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 4
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 4%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('always', N'/ˈɔːlweɪz/', N'luôn luôn', 'Adverb', N'I always brush my teeth.', @CurrentTopicID, NULL, NULL),
    ('often', N'/ˈɒfn/', N'thường xuyên', 'Adverb', N'I often read books.', @CurrentTopicID, NULL, NULL),
    ('sometimes', N'/ˈsʌmtaɪmz/', N'thỉnh thoảng', 'Adverb', N'Sometimes I go swimming.', @CurrentTopicID, NULL, NULL),
    ('usually', N'/ˈjuːʒʊəli/', N'thường xuyên', 'Adverb', N'I usually get up early.', @CurrentTopicID, NULL, NULL),
    ('go for a walk', N'/ɡəʊ fɔːr ə wɔːk/', N'đi dạo', 'Phrasal Verb', N'Lets go for a walk.', @CurrentTopicID, NULL, NULL),
    ('play the violin', N'/pleɪ ðə ˌvaɪəˈlɪn/', N'chơi đàn vi-ô-lông', 'Phrasal Verb', N'She can play the violin.', @CurrentTopicID, NULL, NULL),
    ('surf the Internet', N'/sɜːf ðə ˈɪntənɛt/', N'lướt mạng Internet', 'Phrasal Verb', N'I surf the Internet for fun.', @CurrentTopicID, NULL, NULL),
    ('water the flowers', N'/ˈwɔːtə ðə ˈflaʊəz/', N'tưới hoa', 'Phrasal Verb', N'My mom waters the flowers.', @CurrentTopicID, NULL, NULL),
    ('do gardening', N'/duː ˈɡɑːdnɪŋ/', N'làm vườn', 'Phrasal Verb', N'My dad likes doing gardening.', @CurrentTopicID, NULL, NULL),
    ('collect stamps', N'/kəˈlɛkt stæmps/', N'sưu tầm tem', 'Phrasal Verb', N'He collects stamps.', @CurrentTopicID, NULL, NULL),
    ('read books', N'/riːd bʊks/', N'đọc sách', 'Verb', N'Reading books is good.', @CurrentTopicID, NULL, NULL),
    ('watch TV', N'/wɒtʃ ˌtiːˈviː/', N'xem tivi', 'Verb', N'We watch TV at night.', @CurrentTopicID, NULL, NULL),
    ('play chess', N'/pleɪ tʃɛs/', N'chơi cờ vua', 'Phrasal Verb', N'Can you play chess?', @CurrentTopicID, NULL, NULL),
    ('go swimming', N'/ɡəʊ ˈswɪmɪŋ/', N'đi bơi', 'Phrasal Verb', N'We go swimming in summer.', @CurrentTopicID, NULL, NULL),
    ('relaxing', N'/rɪˈlæksɪŋ/', N'thư giãn', 'Adjective', N'Listening to music is relaxing.', @CurrentTopicID, NULL, NULL),
    ('enjoyable', N'/ɪnˈdʒɔɪəbl/', N'thú vị', 'Adjective', N'The trip was enjoyable.', @CurrentTopicID, NULL, NULL),
    ('cycling', N'/ˈsaɪklɪŋ/', N'đi xe đạp', 'Noun', N'I like cycling in the park.', @CurrentTopicID, NULL, NULL),
    ('fishing', N'/ˈfɪʃɪŋ/', N'câu cá', 'Noun', N'My dad goes fishing on Sunday.', @CurrentTopicID, NULL, NULL),
    ('dancing', N'/ˈdɑːnsɪŋ/', N'khiêu vũ, nhảy múa', 'Noun', N'She loves dancing.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 4.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 4.';
GO
DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 5
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 5%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('job', N'/dʒɒb/', N'công việc', 'Noun', N'What is your dream job?', @CurrentTopicID, NULL, NULL),
    ('engineer', N'/ˌɛndʒɪˈnɪə(r)//', N'kỹ sư', 'Noun', N'He works as an engineer.', @CurrentTopicID, NULL, NULL),
    ('nurse', N'/nɜːs/', N'y tá', 'Noun', N'The nurse helps the doctor.', @CurrentTopicID, NULL, NULL),
    ('artist', N'/ˈɑːtɪst/', N'họa sĩ', 'Noun', N'An artist draws pictures.', @CurrentTopicID, NULL, NULL),
    ('farmer', N'/ˈfɑːmə(r)/', N'nông dân', 'Noun', N'The farmer grows rice.', @CurrentTopicID, NULL, NULL),
    ('pilot', N'/ˈpaɪlət/', N'phi công', 'Noun', N'A pilot flies planes.', @CurrentTopicID, NULL, NULL),
    ('writer', N'/ˈraɪtə(r)/', N'nhà văn', 'Noun', N'She is a famous writer.', @CurrentTopicID, NULL, NULL),
    ('write stories', N'/raɪt ˈstɔːriz/', N'viết truyện', 'Verb', N'She writes stories for kids.', @CurrentTopicID, NULL, NULL),
    ('firefighter', N'/ˈfaɪəfaɪtə/', N'lính cứu hoả', 'Noun', N'Firefighters are brave.', @CurrentTopicID, NULL, NULL),
    ('gardener', N'/ˈɡɑːdnə/', N'người làm vườn', 'Noun', N'The gardener waters flowers.', @CurrentTopicID, NULL, NULL),
    ('grow flowers', N'/ɡrəʊ ˈflaʊə(r)z/', N'trồng hoa', 'Verb', N'My grandma grows flowers.', @CurrentTopicID, NULL, NULL),
    ('reporter', N'/rɪˈpɔːtə/', N'phóng viên', 'Noun', N'A reporter tells the news.', @CurrentTopicID, NULL, NULL),
    ('report the news', N'/rɪˈpɔːt ðə njuːz/', N'đưa tin', 'Verb', N'He reports the news on TV.', @CurrentTopicID, NULL, NULL),
    ('teach children', N'/tiːtʃ ˈtʃɪldrən/', N'dạy trẻ', 'Verb', N'Teachers teach children.', @CurrentTopicID, NULL, NULL),
    ('musician', N'/mjuˈzɪʃn/', N'nhạc sĩ', 'Noun', N'He is a talented musician.', @CurrentTopicID, NULL, NULL),
    ('scientist', N'/ˈsaɪəntɪst/', N'nhà khoa học', 'Noun', N'Scientists discover new things.', @CurrentTopicID, NULL, NULL),
    ('policeman', N'/pəˈliːsmən/', N'cảnh sát nam', 'Noun', N'The policeman helps people.', @CurrentTopicID, NULL, NULL),
    ('policewoman', N'/pəˈliːswʊmən/', N'cảnh sát nữ', 'Noun', N'She is a policewoman.', @CurrentTopicID, NULL, NULL),
    ('interesting', N'/ˈɪntrəstɪŋ/', N'thú vị', 'Adjective', N'This book is interesting.', @CurrentTopicID, NULL, NULL),
    ('exciting', N'/ɪkˈsaɪtɪŋ/', N'hào hứng', 'Adjective', N'The game was exciting.', @CurrentTopicID, NULL, NULL),
    ('helpful', N'/ˈhɛlpfʊl/', N'hữu ích', 'Adjective', N'This tool is very helpful.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 5.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 5.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 6
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 6%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('school', N'/skuːl/', N'trường học', 'Noun', N'My school is big.', @CurrentTopicID, NULL, NULL),
    ('classroom', N'/ˈklɑːsruːm/', N'phòng học', 'Noun', N'Our classroom is clean.', @CurrentTopicID, NULL, NULL),
    ('library', N'/ˈlaɪbrəri/', N'thư viện', 'Noun', N'We read books in the library.', @CurrentTopicID, NULL, NULL),
    ('computer room', N'/kəmˈpjuːtə ruːm/', N'phòng máy tính', 'Noun', N'We learn IT in the computer room.', @CurrentTopicID, NULL, NULL),
    ('art room', N'/ɑːt ruːm/', N'phòng mỹ thuật', 'Noun', N'We draw pictures in the art room.', @CurrentTopicID, NULL, NULL),
    ('music room', N'/ˈmjuːzɪk ruːm/', N'phòng âm nhạc', 'Noun', N'We sing in the music room.', @CurrentTopicID, NULL, NULL),
    ('gym', N'/dʒɪm/', N'phòng thể dục', 'Noun', N'We play sports in the gym.', @CurrentTopicID, NULL, NULL),
    ('science lab', N'/ˈsaɪəns læb/', N'phòng thí nghiệm khoa học', 'Noun', N'We do experiments in the science lab.', @CurrentTopicID, NULL, NULL),
    ('teachers room', N'/ˈtiːtʃəz ruːm/', N'phòng giáo viên', 'Noun', N'The teachers are in the teachers room.', @CurrentTopicID, NULL, NULL),
    ('canteen', N'/kænˈtiːn/', N'căng tin', 'Noun', N'We eat lunch in the canteen.', @CurrentTopicID, NULL, NULL),
    ('playground', N'/ˈpleɪɡraʊnd/', N'sân chơi', 'Noun', N'We play in the playground.', @CurrentTopicID, NULL, NULL),
    ('corridor', N'/ˈkɒrɪdɔː(r)/', N'hành lang', 'Noun', N'Do not run in the corridor.', @CurrentTopicID, NULL, NULL),
    ('first floor', N'/fɜːst flɔː(r)/', N'tầng một', 'Noun', N'My class is on the first floor.', @CurrentTopicID, NULL, NULL),
    ('ground floor', N'/ɡraʊnd flɔː(r)/', N'tầng trệt', 'Noun', N'The office is on the ground floor.', @CurrentTopicID, NULL, NULL),
    ('second floor', N'/ˈsɛkənd flɔː(r)/', N'tầng hai', 'Noun', N'Go to the second floor.', @CurrentTopicID, NULL, NULL),
    ('third floor', N'/θɜːd flɔː(r)/', N'tầng ba', 'Noun', N'The library is on the third floor.', @CurrentTopicID, NULL, NULL),
    ('upstairs', N'/ʌpˈsteəz/', N'ở trên lầu', 'Adverb', N'Go upstairs.', @CurrentTopicID, NULL, NULL),
    ('downstairs', N'/daʊnˈsteəz/', N'ở dưới lầu', 'Adverb', N'Go downstairs.', @CurrentTopicID, NULL, NULL),
    ('go along', N'/ɡəʊ əˈlɒŋ/', N'đi dọc theo', 'Phrasal Verb', N'Go along the corridor.', @CurrentTopicID, NULL, NULL),
    ('past', N'/pɑːst/', N'đi qua', 'Preposition', N'Go past the library.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 6.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 6.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 7
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 7%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('Sports Day', N'/spɔːts deɪ/', N'Ngày hội thể thao', 'Noun', N'We play football on Sports Day.', @CurrentTopicID, NULL, NULL),
    ('Teachers Day', N'/ˈtiːtʃəz deɪ/', N'Ngày Nhà giáo', 'Noun', N'We celebrate Teachers Day in November.', @CurrentTopicID, NULL, NULL),
    ('Independence Day', N'/ˌɪndɪˈpɛndəns deɪ/', N'Ngày Quốc khánh', 'Noun', N'Independence Day is a holiday.', @CurrentTopicID, NULL, NULL),
    ('Childrens Day', N'/ˈtʃɪldrənz deɪ/', N'Ngày Quốc tế Thiếu nhi', 'Noun', N'June 1st is Childrens Day.', @CurrentTopicID, NULL, NULL),
    ('Singing Contest', N'/ˈsɪŋɪŋ ˈkɒntɛst/', N'Cuộc thi hát', 'Noun', N'She won the singing contest.', @CurrentTopicID, NULL, NULL),
    ('play football', N'/pleɪ ˈfʊtbɔːl/', N'chơi bóng đá', 'Verb', N'The boys play football.', @CurrentTopicID, NULL, NULL),
    ('play badminton', N'/pleɪ ˈbædmɪntən/', N'chơi cầu lông', 'Verb', N'We play badminton outside.', @CurrentTopicID, NULL, NULL),
    ('play volleyball', N'/pleɪ ˈvɒlibɔːl/', N'chơi bóng chuyền', 'Verb', N'They play volleyball well.', @CurrentTopicID, NULL, NULL),
    ('do puzzles', N'/duː ˈpʌzlz/', N'giải câu đố', 'Verb', N'I like doing puzzles.', @CurrentTopicID, NULL, NULL),
    ('draw pictures', N'/drɔː ˈpɪktʃəz/', N'vẽ tranh', 'Verb', N'She draws pictures nicely.', @CurrentTopicID, NULL, NULL),
    ('read books', N'/riːd bʊks/', N'đọc sách', 'Verb', N'We read books in the library.', @CurrentTopicID, NULL, NULL),
    ('write stories', N'/raɪt ˈstɔːriz/', N'viết truyện', 'Verb', N'He writes stories for kids.', @CurrentTopicID, NULL, NULL),
    ('sing songs', N'/sɪŋ sɒŋz/', N'hát bài hát', 'Verb', N'Lets sing songs together.', @CurrentTopicID, NULL, NULL),
    ('dance', N'/dɑːns/', N'nhảy múa', 'Verb', N'They dance beautifully.', @CurrentTopicID, NULL, NULL),
    ('play musical instruments', N'/pleɪ ˈmjuːzɪkəl ˈɪnstrʊmənts/', N'chơi nhạc cụ', 'Verb', N'Can you play musical instruments?', @CurrentTopicID, NULL, NULL),
    ('study math', N'/ˈstʌdi mæθ/', N'học toán', 'Verb', N'We study math on Monday.', @CurrentTopicID, NULL, NULL),
    ('do experiments', N'/duː ɪkˈspɛrɪmənts/', N'làm thí nghiệm', 'Verb', N'We do experiments in science class.', @CurrentTopicID, NULL, NULL),
    ('clean the classroom', N'/kliːn ðə ˈklɑːsruːm/', N'dọn dẹp lớp học', 'Verb', N'We clean the classroom daily.', @CurrentTopicID, NULL, NULL),
    ('discuss projects', N'/dɪˈskʌs ˈprɒdʒɛkts/', N'thảo luận dự án', 'Verb', N'Students discuss projects in groups.', @CurrentTopicID, NULL, NULL),
    ('exciting', N'/ɪkˈsaɪtɪŋ/', N'hào hứng', 'Adjective', N'The game was exciting.', @CurrentTopicID, NULL, NULL),
    ('enjoyable', N'/ɪnˈdʒɔɪəbl/', N'thú vị', 'Adjective', N'It was an enjoyable day.', @CurrentTopicID, NULL, NULL),
    ('educational', N'/ˌɛdju(ː)ˈkeɪʃənl/', N'mang tính giáo dục', 'Adjective', N'This book is educational.', @CurrentTopicID, NULL, NULL),
    ('teamwork', N'/ˈtiːmwɜːk/', N'làm việc nhóm', 'Noun', N'Teamwork is important.', @CurrentTopicID, NULL, NULL),
    ('creativity', N'/ˌkriːeɪˈtɪvɪti/', N'sáng tạo', 'Noun', N'Art needs creativity.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 7.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 7.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 8
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 8%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('blackboard', N'/ˈblækbɔːd/', N'bảng đen', 'Noun', N'Look at the blackboard.', @CurrentTopicID, NULL, NULL),
    ('chalk', N'/tʃɔːk/', N'phấn viết', 'Noun', N'The teacher writes with chalk.', @CurrentTopicID, NULL, NULL),
    ('marker', N'/ˈmɑːkə(r)/', N'bút lông', 'Noun', N'I use a marker to draw.', @CurrentTopicID, NULL, NULL),
    ('projector', N'/prəˈdʒɛktə(r)/', N'máy chiếu', 'Noun', N'Turn on the projector.', @CurrentTopicID, NULL, NULL),
    ('pencil case', N'/ˈpɛnsl keɪs/', N'hộp bút', 'Noun', N'My pencil case is blue.', @CurrentTopicID, NULL, NULL),
    ('crayon', N'/ˈkreɪən/', N'bút sáp màu', 'Noun', N'Color with a crayon.', @CurrentTopicID, NULL, NULL),
    ('pencil sharpener', N'/ˈpɛnsl ˈʃɑːpənə(r)/', N'cái gọt bút chì', 'Noun', N'I need a pencil sharpener.', @CurrentTopicID, NULL, NULL),
    ('set square', N'/sɛt skweə(r)/', N'thước ê-ke', 'Noun', N'Use a set square for math.', @CurrentTopicID, NULL, NULL),
    ('scissors', N'/ˈsɪzəz/', N'cây kéo', 'Noun', N'Be careful with scissors.', @CurrentTopicID, NULL, NULL),
    ('classmate', N'/ˈklɑːsmeɪt/', N'bạn cùng lớp', 'Noun', N'He is my classmate.', @CurrentTopicID, NULL, NULL),
    ('above', N'/əˈbʌv/', N'ở phía trên', 'Preposition', N'The clock is above the board.', @CurrentTopicID, NULL, NULL),
    ('under', N'/ˈʌndə(r)/', N'ở phía dưới', 'Preposition', N'The bag is under the desk.', @CurrentTopicID, NULL, NULL),
    ('beside', N'/bɪˈsaɪd/', N'bên cạnh', 'Preposition', N'Sit beside me.', @CurrentTopicID, NULL, NULL),
    ('in front of', N'/ɪn frʌnt əv/', N'ở đằng trước', 'Preposition', N'Stand in front of the class.', @CurrentTopicID, NULL, NULL),
    ('clean the board', N'/kliːn ðə bɔːd/', N'lau bảng', 'Verb', N'Please clean the board.', @CurrentTopicID, NULL, NULL),
    ('write on the board', N'/raɪt ɒn ðə bɔːd/', N'viết lên bảng', 'Verb', N'The teacher writes on the board.', @CurrentTopicID, NULL, NULL),
    ('raise your hand', N'/reɪz jɔː hænd/', N'giơ tay', 'Verb', N'Raise your hand to answer.', @CurrentTopicID, NULL, NULL),
    ('answer the question', N'/ˈɑːnsə ðə ˈkwɛstʃən/', N'trả lời câu hỏi', 'Verb', N'Can you answer the question?', @CurrentTopicID, NULL, NULL),
    ('ask a question', N'/ɑːsk ə ˈkwɛstʃən/', N'đặt câu hỏi', 'Verb', N'May I ask a question?', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 8.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 8.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 9
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 9%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('play football', N'/pleɪ ˈfʊtbɔːl/', N'chơi bóng đá', 'Verb', N'Boys like playing football.', @CurrentTopicID, NULL, NULL),
    ('play badminton', N'/pleɪ ˈbædmɪntən/', N'chơi cầu lông', 'Verb', N'We play badminton in the park.', @CurrentTopicID, NULL, NULL),
    ('play volleyball', N'/pleɪ ˈvɒlibɔːl/', N'chơi bóng chuyền', 'Verb', N'They play volleyball well.', @CurrentTopicID, NULL, NULL),
    ('ride a bicycle', N'/raɪd ə ˈbaɪsɪkl/', N'đi xe đạp', 'Verb', N'I ride a bicycle to school.', @CurrentTopicID, NULL, NULL),
    ('fly a kite', N'/flaɪ ə kaɪt/', N'thả diều', 'Verb', N'Lets fly a kite.', @CurrentTopicID, NULL, NULL),
    ('go swimming', N'/ɡəʊ ˈswɪmɪŋ/', N'đi bơi', 'Verb', N'We go swimming on Sunday.', @CurrentTopicID, NULL, NULL),
    ('go camping', N'/ɡəʊ ˈkæmpɪŋ/', N'đi cắm trại', 'Verb', N'They go camping in the forest.', @CurrentTopicID, NULL, NULL),
    ('go fishing', N'/ɡəʊ ˈfɪʃɪŋ/', N'đi câu cá', 'Verb', N'My dad likes going fishing.', @CurrentTopicID, NULL, NULL),
    ('have a picnic', N'/hæv ə ˈpɪknɪk/', N'tổ chức buổi dã ngoại', 'Verb', N'We have a picnic today.', @CurrentTopicID, NULL, NULL),
    ('play hide and seek', N'/pleɪ haɪd ənd siːk/', N'chơi trốn tìm', 'Verb', N'Children play hide and seek.', @CurrentTopicID, NULL, NULL),
    ('forest', N'/ˈfɒrɪst/', N'khu rừng', 'Noun', N'The forest is green.', @CurrentTopicID, NULL, NULL),
    ('beach', N'/biːtʃ/', N'bãi biển', 'Noun', N'Lets go to the beach.', @CurrentTopicID, NULL, NULL),
    ('mountain', N'/ˈmaʊntɪn/', N'núi', 'Noun', N'We climbed the mountain.', @CurrentTopicID, NULL, NULL),
    ('exciting', N'/ɪkˈsaɪtɪŋ/', N'hào hứng', 'Adjective', N'The game is exciting.', @CurrentTopicID, NULL, NULL),
    ('relaxing', N'/rɪˈlæksɪŋ/', N'thư giãn', 'Adjective', N'Listening to music is relaxing.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 9.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 9.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 10
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 10%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('school trip', N'/skuːl trɪp/', N'chuyến đi thực tế của trường', 'Noun', N'Our school trip was fun.', @CurrentTopicID, NULL, NULL),
    ('Bai Dinh Pagoda', N'/baɪ dɪnh pəˈɡəʊdə/', N'Chùa Bái Đính', 'Noun', N'We visited Bai Dinh Pagoda.', @CurrentTopicID, NULL, NULL),
    ('Ba Na Hills', N'/bɑː nɑː hɪlz/', N'Khu du lịch Bà Nà Hills', 'Noun', N'Ba Na Hills is beautiful.', @CurrentTopicID, NULL, NULL),
    ('Hoan Kiem Lake', N'/hɔːn kiɛm leɪk/', N'Hồ Hoàn Kiếm', 'Noun', N'We walked around Hoan Kiem Lake.', @CurrentTopicID, NULL, NULL),
    ('Suoi Tien Theme Park', N'/swɔɪ tiɛn θiːm pɑːk/', N'Công viên văn hóa Suối Tiên', 'Noun', N'Suoi Tien Theme Park is big.', @CurrentTopicID, NULL, NULL),
    ('historical site', N'/hɪˈstɒrɪkl saɪt/', N'di tích lịch sử', 'Noun', N'It is a famous historical site.', @CurrentTopicID, NULL, NULL),
    ('forest', N'/ˈfɒrɪst/', N'rừng', 'Noun', N'There are many trees in the forest.', @CurrentTopicID, NULL, NULL),
    ('plant trees', N'/plɑːnt triːz/', N'trồng cây', 'Verb', N'We plant trees in spring.', @CurrentTopicID, NULL, NULL),
    ('play games', N'/pleɪ ɡeɪmz/', N'chơi trò chơi', 'Verb', N'They play games together.', @CurrentTopicID, NULL, NULL),
    ('walk around the lake', N'/wɔːk əˈraʊnd ðə leɪk/', N'đi bộ vòng quanh hồ', 'Verb', N'We walked around the lake.', @CurrentTopicID, NULL, NULL),
    ('visit the buildings', N'/ˈvɪzɪt ðə ˈbɪldɪŋz/', N'thăm những tòa nhà', 'Verb', N'Tourists visit the buildings.', @CurrentTopicID, NULL, NULL),
    ('learn about', N'/lɜːn əˈbaʊt/', N'tìm hiểu về', 'Verb', N'We learn about history.', @CurrentTopicID, NULL, NULL),
    ('memorable', N'/ˈmɛmərəbl/', N'đáng nhớ', 'Adjective', N'It was a memorable trip.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 10.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 10.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 11
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 11%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('spend time', N'/spɛnd taɪm/', N'dành thời gian', 'Verb', N'I spend time with my family.', @CurrentTopicID, NULL, NULL),
    ('cook together', N'/kʊk təˈɡɛðə(r)/', N'nấu ăn cùng nhau', 'Verb', N'We cook together on Sundays.', @CurrentTopicID, NULL, NULL),
    ('eat dinner', N'/iːt ˈdɪnə(r)/', N'ăn tối', 'Verb', N'They eat dinner at 7 PM.', @CurrentTopicID, NULL, NULL),
    ('play games', N'/pleɪ ɡeɪmz/', N'chơi trò chơi', 'Verb', N'We play games after dinner.', @CurrentTopicID, NULL, NULL),
    ('watch TV', N'/wɒtʃ ˌtiːˈviː/', N'xem tivi', 'Verb', N'My dad watches TV in the evening.', @CurrentTopicID, NULL, NULL),
    ('go shopping', N'/ɡəʊ ˈʃɒpɪŋ/', N'đi mua sắm', 'Verb', N'Mom goes shopping every week.', @CurrentTopicID, NULL, NULL),
    ('talk about school', N'/tɔːk əˈbaʊt skuːl/', N'nói chuyện về trường học', 'Verb', N'I talk about school with my parents.', @CurrentTopicID, NULL, NULL),
    ('clean the house', N'/kliːn ðə haʊs/', N'dọn dẹp nhà cửa', 'Verb', N'We clean the house together.', @CurrentTopicID, NULL, NULL),
    ('buy souvenirs', N'/baɪ ˈsuːvənɪəz/', N'mua quà lưu niệm', 'Verb', N'We buy souvenirs on vacation.', @CurrentTopicID, NULL, NULL),
    ('collect seashells', N'/kəˈlɛkt ˈsiːʃɛlz/', N'thu lượm vỏ sò', 'Verb', N'She collects seashells on the beach.', @CurrentTopicID, NULL, NULL),
    ('eat seafood', N'/iːt ˈsiːfuːd/', N'ăn hải sản', 'Verb', N'Do you like eating seafood?', @CurrentTopicID, NULL, NULL),
    ('see some interesting places', N'/siː sʌm ˈɪntrəstɪŋ pleɪsɪz/', N'thăm những nơi thú vị', 'Verb', N'We saw some interesting places in Hue.', @CurrentTopicID, NULL, NULL),
    ('take a boat trip around the bay', N'/teɪk ə bəʊt trɪp əˈraʊnd ðə beɪ/', N'đi du lịch bằng tàu quanh vịnh', 'Verb', N'They took a boat trip around the bay.', @CurrentTopicID, NULL, NULL),
    ('walk on the beach', N'/wɔːk ɒn ðə biːtʃ/', N'đi bộ trên bãi biển', 'Verb', N'We walk on the beach every morning.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 11.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 11.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 12
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 12%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('family reunion', N'/ˈfæmɪli riːˈjuːnjən/', N'đoàn tụ gia đình', 'Noun', N'Tet is a time for family reunion.', @CurrentTopicID, NULL, NULL),
    ('New Years Eve', N'/njuː jɪəz iːv/', N'đêm Giao Thừa', 'Noun', N'We watch fireworks on New Years Eve.', @CurrentTopicID, NULL, NULL),
    ('ancestor worship', N'/ˈænsɛstə ˈwɜːʃɪp/', N'thờ cúng tổ tiên', 'Noun', N'Ancestor worship is important.', @CurrentTopicID, NULL, NULL),
    ('kumquat tree', N'/ˈkʌmkwɒt triː/', N'cây quất', 'Noun', N'We buy a kumquat tree for Tet.', @CurrentTopicID, NULL, NULL),
    ('peach blossom', N'/piːtʃ ˈblɒsəm/', N'hoa đào', 'Noun', N'Peach blossom is pink.', @CurrentTopicID, NULL, NULL),
    ('apricot blossom', N'/ˈeɪprɪkɒt ˈblɒsəm/', N'hoa mai', 'Noun', N'Apricot blossom is yellow.', @CurrentTopicID, NULL, NULL),
    ('sticky rice cake', N'/ˈstɪki raɪs keɪk/', N'bánh chưng, bánh tét', 'Noun', N'I love sticky rice cake.', @CurrentTopicID, NULL, NULL),
    ('lucky money', N'/ˈlʌki ˈmʌni/', N'tiền lì xì', 'Noun', N'Children get lucky money.', @CurrentTopicID, NULL, NULL),
    ('red envelope', N'/rɛd ˈɛnvələʊp/', N'phong bao lì xì', 'Noun', N'Put money in the red envelope.', @CurrentTopicID, NULL, NULL),
    ('decorate', N'/ˈdɛkəreɪt/', N'trang trí', 'Verb', N'We decorate our house.', @CurrentTopicID, NULL, NULL),
    ('clean the house', N'/kliːn ðə haʊs/', N'dọn dẹp nhà cửa', 'Verb', N'Mom is cleaning the house.', @CurrentTopicID, NULL, NULL),
    ('visit relatives', N'/ˈvɪzɪt ˈrɛlətɪvz/', N'thăm họ hàng', 'Verb', N'We visit relatives during Tet.', @CurrentTopicID, NULL, NULL),
    ('make offerings', N'/meɪk ˈɒfərɪŋz/', N'làm lễ cúng', 'Verb', N'They make offerings to ancestors.', @CurrentTopicID, NULL, NULL),
    ('watch fireworks', N'/wɒtʃ ˈfaɪəwɜːks/', N'xem pháo hoa', 'Verb', N'Lets watch fireworks tonight.', @CurrentTopicID, NULL, NULL),
    ('wish for good luck', N'/wɪʃ fɔː ɡʊd lʌk/', N'cầu mong may mắn', 'Verb', N'People wish for good luck.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 12.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 12.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 13
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 13%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('birthday', N'/ˈbɜːθdeɪ/', N'sinh nhật', 'Noun', N'Happy birthday to you!', @CurrentTopicID, NULL, NULL),
    ('wedding anniversary', N'/ˈwɛdɪŋ ˌænɪˈvɜːsəri/', N'kỷ niệm ngày cưới', 'Noun', N'It is their wedding anniversary.', @CurrentTopicID, NULL, NULL),
    ('Teachers Day', N'/ˈtiːtʃəz deɪ/', N'Ngày Nhà giáo Việt Nam', 'Noun', N'November 20th is Teachers Day.', @CurrentTopicID, NULL, NULL),
    ('Childrens Day', N'/ˈtʃɪldrənz deɪ/', N'Ngày Quốc tế Thiếu nhi', 'Noun', N'Children love Childrens Day.', @CurrentTopicID, NULL, NULL),
    ('Sports Day', N'/spɔːts deɪ/', N'Ngày hội thể thao', 'Noun', N'We play football on Sports Day.', @CurrentTopicID, NULL, NULL),
    ('Mid-Autumn Festival', N'/mɪd ˈɔːtəm ˈfɛstəvəl/', N'Tết Trung Thu', 'Noun', N'We eat mooncakes at Mid-Autumn Festival.', @CurrentTopicID, NULL, NULL),
    ('Christmas', N'/ˈkrɪsməs/', N'Giáng sinh', 'Noun', N'We get gifts at Christmas.', @CurrentTopicID, NULL, NULL),
    ('New Year', N'/njuː jɪə(r)/', N'Năm mới', 'Noun', N'Happy New Year!', @CurrentTopicID, NULL, NULL),
    ('Independence Day', N'/ˌɪndɪˈpɛndəns deɪ/', N'Ngày Quốc khánh', 'Noun', N'September 2nd is Independence Day.', @CurrentTopicID, NULL, NULL),
    ('apple juice', N'/ˈæpl dʒuːs/', N'nước ép táo', 'Noun', N'I drink apple juice.', @CurrentTopicID, NULL, NULL),
    ('burgers', N'/ˈbɜːgəz/', N'những bánh mì kẹp thịt', 'Noun', N'Do you like burgers?', @CurrentTopicID, NULL, NULL),
    ('at Mid-Autumn Festival', N'/æt mɪd ˈɔːtəm ˈfɛstəvəl/', N'vào Tết Trung thu', 'Prepositional Phrase', N'We have fun at Mid-Autumn Festival.', @CurrentTopicID, NULL, NULL),
    ('on Childrens Day', N'/ɒn ˈtʃɪldrənz deɪ/', N'vào ngày Quốc tế Thiếu nhi', 'Prepositional Phrase', N'No school on Childrens Day.', @CurrentTopicID, NULL, NULL),
    ('on Teachers Day', N'/ɒn ˈtiːtʃəz deɪ/', N'vào ngày Nhà giáo Việt Nam', 'Prepositional Phrase', N'We visit teachers on Teachers Day.', @CurrentTopicID, NULL, NULL),
    ('on Sports Day', N'/ɒn spɔːts deɪ/', N'vào ngày hội thể thao', 'Prepositional Phrase', N'We run on Sports Day.', @CurrentTopicID, NULL, NULL),
    ('celebrate', N'/ˈsɛlɪbreɪt/', N'tổ chức lễ kỷ niệm', 'Verb', N'How do you celebrate your birthday?', @CurrentTopicID, NULL, NULL),
    ('give presents', N'/gɪv ˈprɛznts/', N'tặng quà', 'Verb', N'I give presents to my mom.', @CurrentTopicID, NULL, NULL),
    ('receive gifts', N'/rɪˈsiːv gɪfts/', N'nhận quà', 'Verb', N'Did you receive gifts?', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 13.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 13.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 14
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 14%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('healthy', N'/ˈhɛlθi/', N'khỏe mạnh', 'Adjective', N'Fruit is healthy food.', @CurrentTopicID, NULL, NULL),
    ('exercise', N'/ˈɛksəsaɪz/', N'tập thể dục', 'Verb/Noun', N'Morning exercise is good.', @CurrentTopicID, NULL, NULL),
    ('eat vegetables', N'/iːt ˈvɛdʒtəblz/', N'ăn rau', 'Verb', N'You should eat vegetables.', @CurrentTopicID, NULL, NULL),
    ('drink water', N'/drɪŋk ˈwɔːtə/', N'uống nước', 'Verb', N'Drink lots of water.', @CurrentTopicID, NULL, NULL),
    ('get enough sleep', N'/gɛt ɪˈnʌf sliːp/', N'ngủ đủ giấc', 'Verb', N'Children need to get enough sleep.', @CurrentTopicID, NULL, NULL),
    ('avoid junk food', N'/əˈvɔɪd dʒʌŋk fuːd/', N'tránh thức ăn nhanh', 'Verb', N'Avoid junk food to stay healthy.', @CurrentTopicID, NULL, NULL),
    ('wash hands', N'/wɒʃ hændz/', N'rửa tay', 'Verb', N'Wash hands before eating.', @CurrentTopicID, NULL, NULL),
    ('brush teeth', N'/brʌʃ tiːθ/', N'đánh răng', 'Verb', N'Brush teeth twice a day.', @CurrentTopicID, NULL, NULL),
    ('have a balanced diet', N'/hæv ə ˈbælənst ˈdaɪət/', N'có chế độ ăn cân đối', 'Verb', N'It is important to have a balanced diet.', @CurrentTopicID, NULL, NULL),
    ('go jogging', N'/gəʊ ˈdʒɒgɪŋ/', N'chạy bộ', 'Verb', N'My dad goes jogging.', @CurrentTopicID, NULL, NULL),
    ('ride a bike', N'/raɪd ə baɪk/', N'đạp xe', 'Verb', N'I ride a bike to school.', @CurrentTopicID, NULL, NULL),
    ('every day', N'/ˈɛvri deɪ/', N'mỗi ngày', 'Adverb', N'I exercise every day.', @CurrentTopicID, NULL, NULL),
    ('once a week', N'/wʌns ə wiːk/', N'một lần một tuần', 'Adverb', N'I swim once a week.', @CurrentTopicID, NULL, NULL),
    ('twice a week', N'/twaɪs ə wiːk/', N'hai lần một tuần', 'Adverb', N'We have English twice a week.', @CurrentTopicID, NULL, NULL),
    ('three times a week', N'/θriː taɪmz ə wiːk/', N'ba lần một tuần', 'Adverb', N'He runs three times a week.', @CurrentTopicID, NULL, NULL),
    ('relaxing', N'/rɪˈlæksɪŋ/', N'thư giãn', 'Adjective', N'Yoga is relaxing.', @CurrentTopicID, NULL, NULL),
    ('energetic', N'/ˌɛnəˈdʒɛtɪk/', N'tràn đầy năng lượng', 'Adjective', N'She feels energetic.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 14.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 14.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 15
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 15%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('health', N'/hɛlθ/', N'sức khỏe', 'Noun', N'Health is wealth.', @CurrentTopicID, NULL, NULL),
    ('illness', N'/ˈɪlnəs/', N'bệnh tật', 'Noun', N'He has a serious illness.', @CurrentTopicID, NULL, NULL),
    ('fever', N'/ˈfiːvə/', N'sốt', 'Noun', N'She has a high fever.', @CurrentTopicID, NULL, NULL),
    ('headache', N'/ˈhɛdˌeɪk/', N'đau đầu', 'Noun', N'I have a headache.', @CurrentTopicID, NULL, NULL),
    ('stomachache', N'/ˈstʌməkˌeɪk/', N'đau bụng', 'Noun', N'He ate too much and got a stomachache.', @CurrentTopicID, NULL, NULL),
    ('cough', N'/kɒf/', N'ho', 'Noun/Verb', N'She has a bad cough.', @CurrentTopicID, NULL, NULL),
    ('sore throat', N'/sɔː θrəʊt/', N'đau họng', 'Noun', N'Does he have a sore throat?', @CurrentTopicID, NULL, NULL),
    ('runny nose', N'/ˈrʌni nəʊz/', N'sổ mũi', 'Noun', N'I have a runny nose.', @CurrentTopicID, NULL, NULL),
    ('cold', N'/kəʊld/', N'cảm lạnh', 'Noun', N'Catch a cold.', @CurrentTopicID, NULL, NULL),
    ('medicine', N'/ˈmɛdsɪn/', N'thuốc', 'Noun', N'Take some medicine.', @CurrentTopicID, NULL, NULL),
    ('doctor', N'/ˈdɒktə/', N'bác sĩ', 'Noun', N'Go to the doctor.', @CurrentTopicID, NULL, NULL),
    ('nurse', N'/nɜːs/', N'y tá', 'Noun', N'The nurse is helpful.', @CurrentTopicID, NULL, NULL),
    ('take medicine', N'/teɪk ˈmɛdsɪn/', N'uống thuốc', 'Verb', N'You should take medicine.', @CurrentTopicID, NULL, NULL),
    ('see a doctor', N'/siː ə ˈdɒktə/', N'đi khám bác sĩ', 'Verb', N'You should see a doctor.', @CurrentTopicID, NULL, NULL),
    ('rest', N'/rɛst/', N'nghỉ ngơi', 'Verb', N'You should rest in bed.', @CurrentTopicID, NULL, NULL),
    ('drink lots of water', N'/drɪŋk lɒts əv ˈwɔːtə/', N'uống nhiều nước', 'Verb', N'Drink lots of water when you are sick.', @CurrentTopicID, NULL, NULL),
    ('avoid getting sick', N'/əˈvɔɪd ˈgɛtɪŋ sɪk/', N'tránh bị bệnh', 'Verb', N'Wash hands to avoid getting sick.', @CurrentTopicID, NULL, NULL),
    ('healthy', N'/ˈhɛlθi/', N'khỏe mạnh', 'Adjective', N'Eat healthy food.', @CurrentTopicID, NULL, NULL),
    ('tired', N'/ˈtaɪəd/', N'mệt mỏi', 'Adjective', N'I feel tired.', @CurrentTopicID, NULL, NULL),
    ('weak', N'/wiːk/', N'yếu', 'Adjective', N'He feels weak after illness.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 15.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 15.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 16
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 16%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('season', N'/ˈsiːzn/', N'mùa', 'Noun', N'There are four seasons in a year.', @CurrentTopicID, NULL, NULL),
    ('spring', N'/sprɪŋ/', N'mùa xuân', 'Noun', N'Flowers bloom in spring.', @CurrentTopicID, NULL, NULL),
    ('summer', N'/ˈsʌmə(r)/', N'mùa hè', 'Noun', N'It is hot in summer.', @CurrentTopicID, NULL, NULL),
    ('autumn', N'/ˈɔːtəm/', N'mùa thu', 'Noun', N'Leaves fall in autumn.', @CurrentTopicID, NULL, NULL),
    ('winter', N'/ˈwɪntə(r)/', N'mùa đông', 'Noun', N'It is cold in winter.', @CurrentTopicID, NULL, NULL),
    ('sunny', N'/ˈsʌni/', N'trời nắng', 'Adjective', N'It is a sunny day.', @CurrentTopicID, NULL, NULL),
    ('rainy', N'/ˈreɪni/', N'trời mưa', 'Adjective', N'I do not like rainy weather.', @CurrentTopicID, NULL, NULL),
    ('windy', N'/ˈwɪndi/', N'trời gió', 'Adjective', N'It is windy today.', @CurrentTopicID, NULL, NULL),
    ('cloudy', N'/ˈklaʊdi/', N'nhiều mây', 'Adjective', N'The sky is cloudy.', @CurrentTopicID, NULL, NULL),
    ('storm', N'/stɔːm/', N'bão', 'Noun', N'A big storm is coming.', @CurrentTopicID, NULL, NULL),
    ('temperature', N'/ˈtɛmprətʃə(r)/', N'nhiệt độ', 'Noun', N'The temperature is high.', @CurrentTopicID, NULL, NULL),
    ('wear warm clothes', N'/weə wɔːm kləʊðz/', N'mặc quần áo ấm', 'Verb', N'Wear warm clothes in winter.', @CurrentTopicID, NULL, NULL),
    ('go swimming', N'/ɡəʊ ˈswɪmɪŋ/', N'đi bơi', 'Verb', N'Lets go swimming.', @CurrentTopicID, NULL, NULL),
    ('fly a kite', N'/flaɪ ə kaɪt/', N'thả diều', 'Verb', N'We fly a kite in the park.', @CurrentTopicID, NULL, NULL),
    ('build a snowman', N'/bɪld ə ˈsnəʊmæn/', N'làm người tuyết', 'Verb', N'Children like building a snowman.', @CurrentTopicID, NULL, NULL),
    ('jeans', N'/dʒiːnz/', N'quần bằng vải bông', 'Noun', N'I wear blue jeans.', @CurrentTopicID, NULL, NULL),
    ('jumper', N'/ˈdʒʌmpə(r)/', N'áo len cao cổ', 'Noun', N'Put on your jumper.', @CurrentTopicID, NULL, NULL),
    ('trousers', N'/ˈtraʊzəz/', N'quần dài', 'Noun', N'My trousers are black.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 16.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 16.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 17
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 17%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('story', N'/ˈstɔːri/', N'câu chuyện', 'Noun', N'Tell me a story.', @CurrentTopicID, NULL, NULL),
    ('fairy tale', N'/ˈfeəri teɪl/', N'truyện cổ tích', 'Noun', N'I love reading fairy tales.', @CurrentTopicID, NULL, NULL),
    ('character', N'/ˈkærəktə(r)/', N'nhân vật', 'Noun', N'Who is the main character?', @CurrentTopicID, NULL, NULL),
    ('king', N'/kɪŋ/', N'vua', 'Noun', N'The king lives in a castle.', @CurrentTopicID, NULL, NULL),
    ('queen', N'/kwiːn/', N'hoàng hậu', 'Noun', N'The queen is beautiful.', @CurrentTopicID, NULL, NULL),
    ('prince', N'/prɪns/', N'hoàng tử', 'Noun', N'The prince is brave.', @CurrentTopicID, NULL, NULL),
    ('princess', N'/ˈprɪnsɛs/', N'công chúa', 'Noun', N'The princess wears a dress.', @CurrentTopicID, NULL, NULL),
    ('dragon', N'/ˈdræɡən/', N'rồng', 'Noun', N'The dragon breathes fire.', @CurrentTopicID, NULL, NULL),
    ('hero', N'/ˈhɪərəʊ/', N'anh hùng', 'Noun', N'He is a superhero.', @CurrentTopicID, NULL, NULL),
    ('villain', N'/ˈvɪlən/', N'nhân vật phản diện', 'Noun', N'The villain is bad.', @CurrentTopicID, NULL, NULL),
    ('magical', N'/ˈmædʒɪkl/', N'kỳ diệu, huyền diệu', 'Adjective', N'It is a magical world.', @CurrentTopicID, NULL, NULL),
    ('adventure', N'/ədˈvɛntʃə(r)/', N'cuộc phiêu lưu', 'Noun', N'Going on an adventure.', @CurrentTopicID, NULL, NULL),
    ('lesson', N'/ˈlɛsn/', N'bài học', 'Noun', N'This story has a good lesson.', @CurrentTopicID, NULL, NULL),
    ('kind', N'/kaɪnd/', N'tử tế', 'Adjective', N'She is very kind.', @CurrentTopicID, NULL, NULL),
    ('brave', N'/breɪv/', N'dũng cảm', 'Adjective', N'Be brave!', @CurrentTopicID, NULL, NULL),
    ('clever', N'/ˈklɛvə(r)/', N'thông minh', 'Adjective', N'The fox is clever.', @CurrentTopicID, NULL, NULL),
    ('mean', N'/miːn/', N'độc ác', 'Adjective', N'The witch is mean.', @CurrentTopicID, NULL, NULL),
    ('fight', N'/faɪt/', N'chiến đấu', 'Verb', N'They fight the monster.', @CurrentTopicID, NULL, NULL),
    ('rescue', N'/ˈrɛskjuː/', N'cứu', 'Verb', N'He rescued the cat.', @CurrentTopicID, NULL, NULL),
    ('defeat', N'/dɪˈfiːt/', N'đánh bại', 'Verb', N'The hero defeats the villain.', @CurrentTopicID, NULL, NULL),
    ('live happily ever after', N'/lɪv ˈhæpɪli ˈɛvər ˈɑːftə/', N'sống hạnh phúc mãi mãi', 'Phrase', N'They lived happily ever after.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 17.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 17.';
GO


DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 18
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 18%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('transport', N'/ˈtrænspɔːt/', N'giao thông, vận chuyển', 'Noun', N'Public transport is cheap.', @CurrentTopicID, NULL, NULL),
    ('bicycle', N'/ˈbaɪsɪkl/', N'xe đạp', 'Noun', N'I ride my bicycle to school.', @CurrentTopicID, NULL, NULL),
    ('motorbike', N'/ˈməʊtəˌbaɪk/', N'xe máy', 'Noun', N'He rides a motorbike.', @CurrentTopicID, NULL, NULL),
    ('car', N'/kɑː(r)/', N'ô tô', 'Noun', N'My dad drives a car.', @CurrentTopicID, NULL, NULL),
    ('bus', N'/bʌs/', N'xe buýt', 'Noun', N'We take the bus.', @CurrentTopicID, NULL, NULL),
    ('train', N'/treɪn/', N'tàu hỏa', 'Noun', N'The train is fast.', @CurrentTopicID, NULL, NULL),
    ('airplane', N'/ˈeəpleɪn/', N'máy bay', 'Noun', N'Look at the airplane!', @CurrentTopicID, NULL, NULL),
    ('boat', N'/bəʊt/', N'thuyền', 'Noun', N'We sail a boat.', @CurrentTopicID, NULL, NULL),
    ('ship', N'/ʃɪp/', N'tàu thủy', 'Noun', N'A big ship on the sea.', @CurrentTopicID, NULL, NULL),
    ('taxi', N'/ˈtæksi/', N'xe taxi', 'Noun', N'Take a taxi home.', @CurrentTopicID, NULL, NULL),
    ('subway', N'/ˈsʌbweɪ/', N'tàu điện ngầm', 'Noun', N'The subway is underground.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 18.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 18.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 19
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 19%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('historical site', N'/hɪˈstɒrɪkl saɪt/', N'di tích lịch sử', 'Noun', N'We visited a historical site.', @CurrentTopicID, NULL, NULL),
    ('pagoda', N'/pəˈɡəʊdə/', N'chùa', 'Noun', N'The pagoda is old.', @CurrentTopicID, NULL, NULL),
    ('lake', N'/leɪk/', N'hồ nước', 'Noun', N'The lake is blue.', @CurrentTopicID, NULL, NULL),
    ('beach', N'/biːtʃ/', N'bãi biển', 'Noun', N'Lets go to the beach.', @CurrentTopicID, NULL, NULL),
    ('forest', N'/ˈfɒrɪst/', N'rừng', 'Noun', N'Animals live in the forest.', @CurrentTopicID, NULL, NULL),
    ('mountain', N'/ˈmaʊntɪn/', N'núi', 'Noun', N'Climb the mountain.', @CurrentTopicID, NULL, NULL),
    ('waterfall', N'/ˈwɔːtəfɔːl/', N'thác nước', 'Noun', N'The waterfall is beautiful.', @CurrentTopicID, NULL, NULL),
    ('national park', N'/ˈnæʃnəl pɑːk/', N'vườn quốc gia', 'Noun', N'Cuc Phuong National Park.', @CurrentTopicID, NULL, NULL),
    ('go sightseeing', N'/ɡəʊ ˈsaɪtsiːɪŋ/', N'đi tham quan', 'Verb', N'Tourists go sightseeing.', @CurrentTopicID, NULL, NULL),
    ('take photos', N'/teɪk ˈfəʊtəʊz/', N'chụp ảnh', 'Verb', N'I take photos of flowers.', @CurrentTopicID, NULL, NULL),
    ('explore', N'/ɪkˈsplɔː(r)/', N'khám phá', 'Verb', N'Explore the cave.', @CurrentTopicID, NULL, NULL),
    ('visit', N'/ˈvɪzɪt/', N'thăm', 'Verb', N'Visit the museum.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 19.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 19.';
GO

DECLARE @CurrentTopicID INT;

-- Lấy ID Unit 20
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 20%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID, AudioURL, ImageURL) VALUES 
    ('summer holiday', N'/ˈsʌmə ˈhɒlədeɪ/', N'kỳ nghỉ hè', 'Noun', N'I love summer holiday.', @CurrentTopicID, NULL, NULL),
    ('beach', N'/biːtʃ/', N'bãi biển', 'Noun', N'Play on the beach.', @CurrentTopicID, NULL, NULL),
    ('mountain', N'/ˈmaʊntɪn/', N'núi', 'Noun', N'Cool air on the mountain.', @CurrentTopicID, NULL, NULL),
    ('lake', N'/leɪk/', N'hồ nước', 'Noun', N'Fish in the lake.', @CurrentTopicID, NULL, NULL),
    ('park', N'/pɑːk/', N'công viên', 'Noun', N'Run in the park.', @CurrentTopicID, NULL, NULL),
    ('waterfall', N'/ˈwɔːtəfɔːl/', N'thác nước', 'Noun', N'Look at the waterfall.', @CurrentTopicID, NULL, NULL),
    ('hotel', N'/həʊˈtɛl/', N'khách sạn', 'Noun', N'Stay in a hotel.', @CurrentTopicID, NULL, NULL),
    ('travel', N'/ˈtrævl/', N'đi du lịch', 'Verb', N'We travel by bus.', @CurrentTopicID, NULL, NULL),
    ('go swimming', N'/ɡəʊ ˈswɪmɪŋ/', N'đi bơi', 'Verb', N'Go swimming in the sea.', @CurrentTopicID, NULL, NULL),
    ('go camping', N'/ɡəʊ ˈkæmpɪŋ/', N'đi cắm trại', 'Verb', N'Go camping with friends.', @CurrentTopicID, NULL, NULL),
    ('fly a kite', N'/flaɪ ə kaɪt/', N'thả diều', 'Verb', N'Fly a kite high.', @CurrentTopicID, NULL, NULL);

    PRINT N'Đã thêm từ vựng vào Unit 20.';
END
ELSE
    PRINT N'Lỗi: Không tìm thấy Unit 20.';
GO

DECLARE @CurrentTopicID INT;

-- ==========================================================
-- UNIT 1: All about me! (Tất cả về tôi)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 1%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi và trả lời về thông tin cá nhân', 
        N'Q: Can you tell me about yourself?
A: I''m in Grade + [Lớp]. I live in + [Nơi chốn].', 
        N'Dùng để hỏi và giới thiệu ngắn gọn về bản thân (lớp học, nơi sống).', 
        N'Q: Can you tell me about yourself?
A: I''m in Grade 5. I live in Hanoi.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về sở thích (màu sắc)', 
        N'Q: What''s your favourite + [Danh từ]?
A: It''s + [Màu sắc/Sở thích].', 
        N'Dùng để hỏi về điều yêu thích nhất của ai đó (ví dụ: màu sắc).', 
        N'Q: What''s your favourite color?
A: It''s blue.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 1 chuẩn ZIM.';
END

-- ==========================================================
-- UNIT 2: Our homes (Ngôi nhà của chúng ta)
-- Nguồn: zim.vn/ngu-phap-tieng-anh-lop-5
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 2%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi về nơi sinh sống (Yes/No Question)', 
        N'Q: Do you live in this / that + [Nơi chốn]?
A: Yes, I do. / No, I don''t.', 
        N'Dùng để xác nhận xem ai đó có sống ở một địa điểm cụ thể hay không.', 
        N'Q: Do you live in this house?
A: Yes, I do.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về địa chỉ nhà', 
        N'Q: What''s your address?
A: It''s + [Số nhà, Tên đường...].', 
        N'Dùng để hỏi địa chỉ cụ thể của ai đó.', 
        N'Q: What''s your address?
A: It''s 123 Le Duan Street.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 2 chuẩn ZIM.';
END

-- ==========================================================
-- UNIT 3: My foreign friends (Những người bạn nước ngoài)
-- Nguồn: zim.vn/ngu-phap-tieng-anh-lop-5
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 3%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi về quốc tịch', 
        N'Q: What nationality is he/she?
A: He''s / She''s + [Quốc tịch].', 
        N'Dùng để hỏi xem người khác mang quốc tịch gì.', 
        N'Q: What nationality is she?
A: She''s Japanese.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về tính cách', 
        N'Q: What''s he/she like?
A: He''s / She''s + [Tính từ chỉ tính cách].', 
        N'Dùng để hỏi về đặc điểm tính cách của một người.', 
        N'Q: What''s he like?
A: He''s very friendly.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 3 chuẩn ZIM.';
END

-- ==========================================================
-- UNIT 4: Our free-time activities (Hoạt động giải trí)
-- Nguồn: zim.vn/ngu-phap-tieng-anh-lop-5
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 4%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi về sở thích trong thời gian rảnh', 
        N'Q: What do you like doing in your free time?
A: I like + [Động từ thêm -ing].', 
        N'Dùng để hỏi về hoạt động yêu thích khi rảnh rỗi.', 
        N'Q: What do you like doing in your free time?
A: I like reading books.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về hoạt động cuối tuần', 
        N'Q: What do you do at the weekend?
A: I + [Trạng từ tần suất] + [Hoạt động].', 
        N'Dùng để hỏi thói quen sinh hoạt vào dịp cuối tuần.', 
        N'Q: What do you do at the weekend?
A: I usually go swimming.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 4 chuẩn ZIM.';
END

-- ==========================================================
-- UNIT 5: My future job (Nghề nghiệp tương lai)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 5%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi về ước mơ nghề nghiệp', 
        N'Q: What would you like to be in the future?
A: I''d like to be a/an + [Nghề nghiệp].', 
        N'Dùng để hỏi về nghề nghiệp mong muốn trong tương lai.', 
        N'Q: What would you like to be in the future?
A: I''d like to be a doctor.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi lý do chọn nghề nghiệp', 
        N'Q: Why would you like to be a/an + [Nghề nghiệp]?
A: Because I''d like to + [Lý do/Hành động].', 
        N'Dùng để giải thích lý do tại sao muốn làm nghề đó.', 
        N'Q: Why would you like to be a doctor?
A: Because I''d like to help people.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 5 chuẩn ZIM.';
END
GO
DECLARE @CurrentTopicID INT;
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 6%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi vị trí của các phòng học', 
        N'Q: Where''s the + [Tên phòng]?
A: It''s + [Giới từ chỉ vị trí] + the + [Vị trí].', 
        N'Dùng để hỏi và chỉ đường/vị trí của một phòng học nào đó trong trường.', 
        N'Q: Where''s the computer room? (Phòng máy tính ở đâu?)
A: It''s on the second floor. (Nó ở tầng hai.)', 
        @CurrentTopicID
    ),
    (
        N'Giới từ chỉ vị trí (Place Prepositions)', 
        N'on the first floor (ở tầng 1)
on the ground floor (ở tầng trệt)
next to (bên cạnh), opposite (đối diện)...', 
        N'Các cụm từ thường dùng để mô tả vị trí trong trường học.', 
        N'The library is on the first floor.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 6.';
END

-- ==========================================================
-- UNIT 7: Our favourite school activities (Hoạt động ở trường)
-- Ngữ pháp: Hỏi thời gian sự kiện (When is...?)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 7%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi thời gian diễn ra sự kiện', 
        N'Q: When is + [Tên sự kiện]?
A: It''s in + [Tháng]. 
Hoặc: A: It''s on + [Ngày/Thứ].', 
        N'Dùng để hỏi về thời điểm tổ chức các ngày lễ hoặc sự kiện ở trường.', 
        N'Q: When is Sports Day? (Ngày hội thể thao là khi nào?)
A: It''s in November. (Vào tháng 11.)', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 7.';
END

-- ==========================================================
-- UNIT 8: In our classroom (Trong lớp học)
-- Ngữ pháp: Xin phép và cho phép (May I...?)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 8%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Câu xin phép làm gì đó', 
        N'Q: May I + [Động từ nguyên thể]?
A: Yes, you can. (Đồng ý)
A: No, you can''t. (Từ chối)', 
        N'Dùng để xin phép giáo viên hoặc người khác làm một việc gì đó.', 
        N'Q: May I open the book? (Em mở sách ra được không?)
A: Yes, you can. (Được, em mở đi.)', 
        @CurrentTopicID
    ),
    (
        N'Câu mệnh lệnh trong lớp học', 
        N'Khẳng định: [Động từ] + please!
Phủ định: Don''t + [Động từ] + please!', 
        N'Dùng để yêu cầu ai đó làm hoặc không làm gì.', 
        N'- Stand up, please! (Mời đứng lên)
- Don''t talk, please! (Xin đừng nói chuyện)', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 8.';
END

-- ==========================================================
-- UNIT 9: Our outdoor activities (Hoạt động ngoài trời)
-- Ngữ pháp: Thì hiện tại tiếp diễn (Present Continuous)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 9%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi ai đó đang làm gì', 
        N'Q: What are you doing?
A: I''m + [Verb-ing].

Q: What''s he/she doing?
A: He''s/She''s + [Verb-ing].', 
        N'Dùng để hỏi và trả lời về hành động đang xảy ra ngay lúc nói.', 
        N'Q: What are you doing?
A: I''m playing badminton. (Tớ đang chơi cầu lông.)', 
        @CurrentTopicID
    ),
    (
        N'Hỏi họ đang làm gì (Số nhiều)', 
        N'Q: What are they doing?
A: They''re + [Verb-ing].', 
        N'Dùng để hỏi về hành động của một nhóm người.', 
        N'Q: What are they doing?
A: They''re playing football.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 9.';
END

-- ==========================================================
-- UNIT 10: Our school trip (Chuyến đi dã ngoại)
-- Ngữ pháp: Quá khứ đơn với động từ "to be" (Past Simple)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 10%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi về địa điểm trong quá khứ (Were you...?)', 
        N'Q: Were you at + [Địa điểm] + [Thời gian]?
A: Yes, I was. / No, I wasn''t.', 
        N'Dùng để xác nhận xem ai đó có ở một địa điểm nào đó trong quá khứ không.', 
        N'Q: Were you at the zoo yesterday? (Hôm qua bạn ở sở thú phải không?)
A: Yes, I was.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi bạn đã ở đâu (Where were you...?)', 
        N'Q: Where were you + [Thời gian]?
A: I was at/in + [Địa điểm].', 
        N'Dùng để hỏi cụ thể về vị trí của ai đó trong quá khứ.', 
        N'Q: Where were you last Sunday?
A: I was on the beach.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 10.';
END

SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 11%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi ai đó làm gì vào thời gian cụ thể', 
        N'Q: What do you do + [Thời gian]?
A: I + [Hoạt động].

Q: What does he/she do + [Thời gian]?
A: He/She + [Hoạt động (thêm s/es)].', 
        N'Dùng để hỏi về các hoạt động thường ngày hoặc việc nhà.', 
        N'Q: What does your father do in the morning?
A: He reads newspapers.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 11.';
END

-- ==========================================================
-- UNIT 12: Our Tet Holiday (Ngày Tết của chúng ta)
-- Ngữ pháp: Hỏi về các hoạt động ngày Tết
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 12%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi về việc làm trong dịp Tết', 
        N'Q: What do you do at Tet?
A: I + [Hoạt động].', 
        N'Dùng để hỏi về phong tục hoặc thói quen trong dịp Tết.', 
        N'Q: What do you do at Tet?
A: I decorate the house and visit my grandparents.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về đồ ăn ngày Tết', 
        N'Q: What do you eat at Tet?
A: I eat + [Tên món ăn].', 
        N'Dùng để hỏi về món ăn đặc trưng.', 
        N'Q: What do you eat at Tet?
A: I eat banh chung.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 12.';
END

-- ==========================================================
-- UNIT 13: Our special days (Những ngày đặc biệt)
-- Ngữ pháp: Quá khứ đơn (Past Simple) - Hỏi làm gì trong quá khứ
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 13%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi ai đó đã làm gì vào ngày lễ', 
        N'Q: What did you do on + [Tên ngày lễ]?
A: I + [Động từ quá khứ - V2/ed].', 
        N'Dùng để hỏi về hành động đã xảy ra trong một dịp đặc biệt trong quá khứ.', 
        N'Q: What did you do on Teachers'' Day?
A: I visited my teachers.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 13.';
END

-- ==========================================================
-- UNIT 14: Staying healthy (Sống khỏe mạnh)
-- Ngữ pháp: Đưa ra lời khuyên (Should/Shouldn''t)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 14%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi và trả lời về cách giữ sức khỏe', 
        N'Q: What should I do to stay healthy?
A: You should + [Hoạt động tốt].', 
        N'Dùng để xin lời khuyên về sức khỏe.', 
        N'Q: What should I do to stay healthy?
A: You should do morning exercise.', 
        @CurrentTopicID
    ),
    (
        N'Lời khuyên nên làm gì (Should)', 
        N'You should + [Động từ nguyên thể].', 
        N'Khuyên ai đó nên làm điều gì tốt.', 
        N'You should wash your hands before meals.', 
        @CurrentTopicID
    ),
    (
        N'Lời khuyên không nên làm gì (Shouldn''t)', 
        N'You shouldn''t + [Động từ nguyên thể].', 
        N'Khuyên ai đó tránh làm điều gì có hại.', 
        N'You shouldn''t eat too much candy.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 14.';
END

-- ==========================================================
-- UNIT 15: Our health (Sức khỏe của chúng ta)
-- Ngữ pháp: Hỏi về vấn đề sức khỏe (What''s the matter?)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 15%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi thăm sức khỏe (Có chuyện gì vậy?)', 
        N'Q: What''s the matter with you?
A: I have + [Tên bệnh].', 
        N'Dùng để hỏi khi thấy ai đó trông mệt mỏi hoặc không khỏe.', 
        N'Q: What''s the matter with you?
A: I have a headache.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi thăm người khác (He/She)', 
        N'Q: What''s the matter with him/her?
A: He/She has + [Tên bệnh].', 
        N'Dùng để hỏi về sức khỏe của người thứ ba.', 
        N'Q: What''s the matter with her?
A: She has a toothache.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 15.';
END

-- ==========================================================
-- UNIT 16: Seasons and the weather (Mùa và thời tiết)
-- Ngữ pháp: Hỏi về thời tiết các mùa
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 16%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi thời tiết vào một mùa nào đó', 
        N'Q: What''s the weather like in + [Mùa]?
A: It''s + [Tính từ chỉ thời tiết].', 
        N'Dùng để hỏi đặc điểm thời tiết của từng mùa.', 
        N'Q: What''s the weather like in summer?
A: It''s hot and sunny.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về thời tiết hôm nay', 
        N'Q: What''s the weather like today?
A: It''s + [Thời tiết].', 
        N'Hỏi về tình hình thời tiết hiện tại.', 
        N'Q: What''s the weather like today?
A: It''s cloudy and windy.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 16.';
END

-- ==========================================================
-- UNIT 17: Stories for children (Truyện kể cho bé)
-- Ngữ pháp: Hỏi về nhân vật và tính cách
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 17%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi ý kiến về một nhân vật', 
        N'Q: What do you think of + [Tên nhân vật]?
A: I think he''s/she''s + [Tính từ].', 
        N'Dùng để hỏi cảm nhận, đánh giá về tính cách nhân vật trong truyện.', 
        N'Q: What do you think of the Fox?
A: I think he''s clever.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về loại truyện yêu thích', 
        N'Q: What kinds of stories do you like?
A: I like + [Loại truyện].', 
        N'Dùng để hỏi sở thích đọc truyện.', 
        N'Q: What kinds of stories do you like?
A: I like fairy tales.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 17.';
END

-- ==========================================================
-- UNIT 18: Means of transport (Phương tiện giao thông)
-- Ngữ pháp: Hỏi về cách đi lại (How...?)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 18%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi cách đi đến địa điểm nào đó', 
        N'Q: How can I get to + [Địa điểm]?
A: You can take a + [Phương tiện].
Hoặc: You can go by + [Phương tiện].', 
        N'Dùng để hỏi phương tiện di chuyển đến một nơi.', 
        N'Q: How can I get to the zoo?
A: You can take a bus.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi cách ai đó đi đâu', 
        N'Q: How do you go to school?
A: I go to school by + [Phương tiện].', 
        N'Hỏi về thói quen di chuyển hàng ngày.', 
        N'Q: How do you go to school?
A: I go to school by bike.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 18.';
END

-- ==========================================================
-- UNIT 19: Places of interest (Danh lam thắng cảnh)
-- Ngữ pháp: Hỏi về địa điểm tham quan (Which place...?)
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 19%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi lựa chọn địa điểm muốn đến', 
        N'Q: Which place would you like to visit, [Nơi A] or [Nơi B]?
A: I''d like to visit + [Nơi chọn].', 
        N'Dùng để hỏi về sự lựa chọn giữa hai địa điểm.', 
        N'Q: Which place would you like to visit, Trang Tien Bridge or Thien Mu Pagoda?
A: I''d like to visit Thien Mu Pagoda.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi xem ai đó nghĩ gì về một nơi', 
        N'Q: What do you think of + [Địa điểm]?
A: It''s more + [Tính từ] + than I expected.', 
        N'Dùng để hỏi cảm nhận sau khi thăm một nơi.', 
        N'Q: What do you think of Dam Sen Park?
A: It''s more exciting than I expected.', 
        @CurrentTopicID
    );
    PRINT N'Đã cập nhật ngữ pháp Unit 19.';
END

-- ==========================================================
-- UNIT 20: Our summer holidays (Kỳ nghỉ hè của chúng ta)
-- Ngữ pháp: Tương lai gần (Near Future) - Hỏi dự định
-- ==========================================================
SELECT @CurrentTopicID = TopicID FROM Topics WHERE TopicName LIKE N'Unit 20%';

IF @CurrentTopicID IS NOT NULL
BEGIN
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (
        N'Hỏi về địa điểm sẽ đi trong kỳ nghỉ', 
        N'Q: Where are you going this summer?
A: I''m going to + [Địa điểm].', 
        N'Dùng thì hiện tại tiếp diễn hoặc "be going to" để nói về kế hoạch tương lai.', 
        N'Q: Where are you going this summer?
A: I''m going to Da Nang.', 
        @CurrentTopicID
    ),
    (
        N'Hỏi về kế hoạch làm gì', 
        N'Q: What are you going to do?
A: I''m going to + [Hoạt động].', 
        N'Dùng để hỏi cụ thể về hoạt động dự định làm.', 
        N'Q: What are you going to do there?
A: I''m going to swim in the sea.', 
        @CurrentTopicID
    );
END
GO
SELECT name, type_desc FROM sys.server_principals WHERE name = 'GameUser';
DELETE FROM Vocabulary WHERE Word IN (
    'family', 'friend', 'school', 'classmate', 'hobby', 'active', 'clever', 'friendly', 'helpful', 'kind', 'like', 'play', 'talk', 'share', 'learn', -- Unit 1
    'flat', 'address', 'building', 'tower', 'district', 'comfortable', 'clean', 'tidy', 'messy', 'far', 'near', 'live', 'hometown' -- Unit 2
);
GO
DECLARE @Unit1ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Unit 1:%');

IF @Unit1ID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID) VALUES 
    ('family', N'/ˈfæmɪli/', N'gia đình', 'Noun', N'I love my family.', @Unit1ID),
    ('friend', N'/frend/', N'bạn bè', 'Noun', N'She is my best friend.', @Unit1ID),
    ('school', N'/skuːl/', N'trường học', 'Noun', N'I go to school by bus.', @Unit1ID),
    ('classmate', N'/ˈklɑːsmeɪt/', N'bạn cùng lớp', 'Noun', N'He is my new classmate.', @Unit1ID),
    ('hobby', N'/ˈhɒbi/', N'sở thích', 'Noun', N'My hobby is reading books.', @Unit1ID),
    ('active', N'/ˈæktɪv/', N'năng động', 'Adjective', N'Tom is very active.', @Unit1ID),
    ('clever', N'/ˈklevə/', N'thông minh', 'Adjective', N'She is a clever student.', @Unit1ID),
    ('friendly', N'/ˈfrendli/', N'thân thiện', 'Adjective', N'Our teacher is very friendly.', @Unit1ID),
    ('helpful', N'/ˈhelpfʊl/', N'hữu ích', 'Adjective', N'Thank you for being helpful.', @Unit1ID),
    ('kind', N'/kaɪnd/', N'tử tế', 'Adjective', N'Be kind to others.', @Unit1ID),
    ('like', N'/laɪk/', N'thích', 'Verb', N'I like ice cream.', @Unit1ID),
    ('play', N'/pleɪ/', N'chơi', 'Verb', N'Let''s play football.', @Unit1ID),
    ('talk', N'/tɔːk/', N'nói chuyện', 'Verb', N'Please do not talk in class.', @Unit1ID),
    ('share', N'/ʃeə/', N'chia sẻ', 'Verb', N'Share your toys with friends.', @Unit1ID),
    ('learn', N'/lɜːn/', N'học hỏi', 'Verb', N'We learn English together.', @Unit1ID);
    PRINT N'--- Đã sửa xong Unit 1 ---';
END

-- =======================================================
-- BƯỚC 3: CHÈN LẠI ĐÚNG CHO UNIT 2
-- =======================================================
DECLARE @Unit2ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Unit 2:%');

IF @Unit2ID IS NOT NULL
BEGIN
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID) VALUES 
    ('flat', N'/flæt/', N'căn hộ', 'Noun', N'My flat is small but cozy.', @Unit2ID),
    ('address', N'/ə''dres/', N'địa chỉ', 'Noun', N'What is your address?', @Unit2ID),
    ('building', N'/''bɪldɪŋ/', N'tòa nhà', 'Noun', N'It is a very tall building.', @Unit2ID),
    ('tower', N'/''taʊə(r)/', N'tòa tháp', 'Noun', N'He lives in Tower B.', @Unit2ID),
    ('district', N'/''dɪstrɪkt/', N'quận', 'Noun', N'I live in Cau Giay District.', @Unit2ID),
    ('comfortable', N'/''kʌmfətəbl/', N'thoải mái', 'Adjective', N'This sofa is very comfortable.', @Unit2ID),
    ('clean', N'/kli:n/', N'sạch sẽ', 'Adjective', N'Keep your room clean.', @Unit2ID),
    ('tidy', N'/''taɪdi/', N'ngăn nắp', 'Adjective', N'Her desk is always tidy.', @Unit2ID),
    ('messy', N'/''mesi/', N'bừa bộn', 'Adjective', N'Do not leave your room messy.', @Unit2ID),
    ('far', N'/fɑ:(r)/', N'xa', 'Adjective', N'Is your school far from here?', @Unit2ID),
    ('near', N'/nɪə(r)/', N'gần', 'Adjective', N'My house is near the park.', @Unit2ID),
    ('live', N'/lɪv/', N'sống', 'Verb', N'I live in Hanoi.', @Unit2ID),
    ('hometown', N'/''həʊmtaʊn/', N'quê hương', 'Noun', N'My hometown is Da Nang.', @Unit2ID);
    PRINT N'--- Đã sửa xong Unit 2 ---';
END
GO
DELETE FROM Vocabulary WHERE Word IN (
    -- Unit 1
    'family', 'friend', 'school', 'classmate', 'hobby', 'active', 'clever', 'friendly', 'helpful', 'kind', 'like', 'play', 'talk', 'share', 'learn',
    -- Unit 2
    'flat', 'address', 'building', 'tower', 'district', 'comfortable', 'clean', 'tidy', 'messy', 'far', 'near', 'live', 'hometown'
);

-- 1.2 Xóa Ngữ pháp Unit 1 & 2 cũ (để tránh bị trùng lặp)
DELETE FROM Grammar WHERE GrammarName IN (
    N'Hỏi và trả lời về thông tin cá nhân', 
    N'Hỏi về sở thích (màu sắc)',
    N'Hỏi về nơi sinh sống (Yes/No Question)', 
    N'Hỏi về địa chỉ nhà'
);

-- =======================================================
-- BƯỚC 2: NẠP LẠI DỮ LIỆU CHUẨN CHO UNIT 1
-- (Dùng 'Unit 1:%' có dấu hai chấm để tìm chính xác)
-- =======================================================
PRINT N'--- Đang sửa Unit 1... ---';
DECLARE @Unit1ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Unit 1:%');

IF @Unit1ID IS NOT NULL
BEGIN
    -- Chèn Từ vựng Unit 1
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID) VALUES 
    ('family', N'/ˈfæmɪli/', N'gia đình', 'Noun', N'I love my family.', @Unit1ID),
    ('friend', N'/frend/', N'bạn bè', 'Noun', N'She is my best friend.', @Unit1ID),
    ('school', N'/skuːl/', N'trường học', 'Noun', N'I go to school by bus.', @Unit1ID),
    ('classmate', N'/ˈklɑːsmeɪt/', N'bạn cùng lớp', 'Noun', N'He is my new classmate.', @Unit1ID),
    ('hobby', N'/ˈhɒbi/', N'sở thích', 'Noun', N'My hobby is reading books.', @Unit1ID),
    ('active', N'/ˈæktɪv/', N'năng động', 'Adjective', N'Tom is very active.', @Unit1ID),
    ('clever', N'/ˈklevə/', N'thông minh', 'Adjective', N'She is a clever student.', @Unit1ID),
    ('friendly', N'/ˈfrendli/', N'thân thiện', 'Adjective', N'Our teacher is very friendly.', @Unit1ID),
    ('helpful', N'/ˈhelpfʊl/', N'hữu ích', 'Adjective', N'Thank you for being helpful.', @Unit1ID),
    ('kind', N'/kaɪnd/', N'tử tế', 'Adjective', N'Be kind to others.', @Unit1ID),
    ('like', N'/laɪk/', N'thích', 'Verb', N'I like ice cream.', @Unit1ID),
    ('play', N'/pleɪ/', N'chơi', 'Verb', N'Let''s play football.', @Unit1ID),
    ('talk', N'/tɔːk/', N'nói chuyện', 'Verb', N'Please do not talk in class.', @Unit1ID),
    ('share', N'/ʃeə/', N'chia sẻ', 'Verb', N'Share your toys with friends.', @Unit1ID),
    ('learn', N'/lɜːn/', N'học hỏi', 'Verb', N'We learn English together.', @Unit1ID);

    -- Chèn Ngữ pháp Unit 1
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi và trả lời về thông tin cá nhân', N'Q: Can you tell me about yourself? A: I''m in Grade... I live in...', N'Dùng để hỏi và giới thiệu bản thân.', N'I''m in Grade 5.', @Unit1ID),
    (N'Hỏi về sở thích (màu sắc)', N'Q: What''s your favourite...? A: It''s...', N'Hỏi về điều yêu thích.', N'It''s blue.', @Unit1ID);
END

-- =======================================================
-- BƯỚC 3: NẠP LẠI DỮ LIỆU CHUẨN CHO UNIT 2
-- (Dùng 'Unit 2:%' có dấu hai chấm)
-- =======================================================
PRINT N'--- Đang sửa Unit 2... ---';
DECLARE @Unit2ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Unit 2:%');

IF @Unit2ID IS NOT NULL
BEGIN
    -- Chèn Từ vựng Unit 2
    INSERT INTO Vocabulary (Word, Pronunciation, Meaning, WordType, Example, TopicID) VALUES 
    ('flat', N'/flæt/', N'căn hộ', 'Noun', N'My flat is small but cozy.', @Unit2ID),
    ('address', N'/ə''dres/', N'địa chỉ', 'Noun', N'What is your address?', @Unit2ID),
    ('building', N'/''bɪldɪŋ/', N'tòa nhà', 'Noun', N'It is a very tall building.', @Unit2ID),
    ('tower', N'/''taʊə(r)/', N'tòa tháp', 'Noun', N'He lives in Tower B.', @Unit2ID),
    ('district', N'/''dɪstrɪkt/', N'quận', 'Noun', N'I live in Cau Giay District.', @Unit2ID),
    ('comfortable', N'/''kʌmfətəbl/', N'thoải mái', 'Adjective', N'This sofa is very comfortable.', @Unit2ID),
    ('clean', N'/kli:n/', N'sạch sẽ', 'Adjective', N'Keep your room clean.', @Unit2ID),
    ('tidy', N'/''taɪdi/', N'ngăn nắp', 'Adjective', N'Her desk is always tidy.', @Unit2ID),
    ('messy', N'/''mesi/', N'bừa bộn', 'Adjective', N'Do not leave your room messy.', @Unit2ID),
    ('far', N'/fɑ:(r)/', N'xa', 'Adjective', N'Is your school far from here?', @Unit2ID),
    ('near', N'/nɪə(r)/', N'gần', 'Adjective', N'My house is near the park.', @Unit2ID),
    ('live', N'/lɪv/', N'sống', 'Verb', N'I live in Hanoi.', @Unit2ID),
    ('hometown', N'/''həʊmtaʊn/', N'quê hương', 'Noun', N'My hometown is Da Nang.', @Unit2ID);

    -- Chèn Ngữ pháp Unit 2
    INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID) VALUES 
    (N'Hỏi về nơi sinh sống (Yes/No Question)', N'Q: Do you live in...? A: Yes, I do / No, I don''t.', N'Xác nhận nơi sống.', N'Yes, I do.', @Unit2ID),
    (N'Hỏi về địa chỉ nhà', N'Q: What''s your address? A: It''s...', N'Hỏi địa chỉ.', N'It''s 123 Le Duan St.', @Unit2ID);
END
GO
--Chèn câu hỏi
--Màn 1: Nối từ(matching)
-- 1. Tạo Topic riêng cho Game để dễ quản lý
INSERT INTO Topics (TopicName) VALUES (N'Game Round 1 Pool');
DECLARE @GameTopicID INT = SCOPE_IDENTITY(); -- Lấy ID vừa tạo

-- 2. Tạo 1 câu hỏi "Container" chứa tất cả 20 cặp từ này
-- (Chúng ta gom hết vào 1 QuestionID cho gọn, hoặc chia nhỏ cũng được, 
-- nhưng gom 1 cái thì Query lấy Option sẽ nhanh hơn)
INSERT INTO Questions (TopicID, QuestionText, QuestionType, HintText, CorrectAnswer)
VALUES (@GameTopicID, N'Nối từ vựng (Game Pool)', 'matching', N'Game Round 1', N'All Pairs');

DECLARE @Q_ID INT = SCOPE_IDENTITY();

-- 3. CHÈN 20 CẶP TỪ (POOL DATA) VÀO BẢNG QuestionOptions
-- Format: {"L": "Tiếng Anh", "R": "Tiếng Việt"}
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
-- Nhóm Gia đình & Bạn bè (5)
(@Q_ID, N'{"L": "Family", "R": "Gia đình"}', 1),
(@Q_ID, N'{"L": "Friend", "R": "Bạn bè"}', 1),
(@Q_ID, N'{"L": "Teacher", "R": "Giáo viên"}', 1),
(@Q_ID, N'{"L": "Classmate", "R": "Bạn cùng lớp"}', 1),
(@Q_ID, N'{"L": "Parents", "R": "Bố mẹ"}', 1),

-- Nhóm Nhà cửa (5)
(@Q_ID, N'{"L": "House", "R": "Ngôi nhà"}', 1),
(@Q_ID, N'{"L": "Bedroom", "R": "Phòng ngủ"}', 1),
(@Q_ID, N'{"L": "Kitchen", "R": "Nhà bếp"}', 1),
(@Q_ID, N'{"L": "Garden", "R": "Khu vườn"}', 1),
(@Q_ID, N'{"L": "Living room", "R": "Phòng khách"}', 1),

-- Nhóm Động từ hoạt động (5)
(@Q_ID, N'{"L": "Run", "R": "Chạy"}', 1),
(@Q_ID, N'{"L": "Swim", "R": "Bơi lội"}', 1),
(@Q_ID, N'{"L": "Read", "R": "Đọc sách"}', 1),
(@Q_ID, N'{"L": "Listen", "R": "Nghe"}', 1),
(@Q_ID, N'{"L": "Write", "R": "Viết"}', 1),

-- Nhóm Tính từ (5)
(@Q_ID, N'{"L": "Happy", "R": "Vui vẻ"}', 1),
(@Q_ID, N'{"L": "Sad", "R": "Buồn bã"}', 1),
(@Q_ID, N'{"L": "Big", "R": "To lớn"}', 1),
(@Q_ID, N'{"L": "Small", "R": "Nhỏ bé"}', 1),
(@Q_ID, N'{"L": "Beautiful", "R": "Xinh đẹp"}', 1);

PRINT N'--- Đã tạo kho 20 câu hỏi cho Game Round 1 thành công ---';
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

-- 3. CHÈN 20 CÂU TIẾNG ANH MẪU (Lấy từ chương trình học lớp 5 trong Database)
-- Lưu ý: OptionContent chứa câu ĐÚNG hoàn chỉnh.
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
-- Unit 1: Giới thiệu bản thân
(@Q2_ID, N'I am a pupil at Nguyen Du Primary School', 1),
(@Q2_ID, N'I live with my parents in Hanoi', 1),

-- Unit 2: Nhà cửa
(@Q2_ID, N'My family lives on the third floor of Tower B', 1),
(@Q2_ID, N'It is a small and quiet village', 1),

-- Unit 4: Hoạt động rảnh rỗi
(@Q2_ID, N'I often surf the Internet in my free time', 1),
(@Q2_ID, N'She goes swimming twice a week', 1),

-- Unit 5: Nghề nghiệp
(@Q2_ID, N'I would like to be a writer in the future', 1),
(@Q2_ID, N'Why would you like to be a pilot', 1), -- Câu hỏi

-- Unit 6: Trường học
(@Q2_ID, N'The library is on the first floor', 1),
(@Q2_ID, N'Go along the corridor and turn left', 1),

-- Unit 8: Lớp học
(@Q2_ID, N'May I write on the board', 1),
(@Q2_ID, N'Please do not talk in the class', 1),

-- Unit 9: Thì hiện tại tiếp diễn
(@Q2_ID, N'They are playing badminton in the playground', 1),
(@Q2_ID, N'What is he doing now', 1),

-- Unit 12: Ngày Tết
(@Q2_ID, N'We decorate our house before Tet', 1),
(@Q2_ID, N'I get lucky money from my grandparents', 1),

-- Unit 14: Sức khỏe
(@Q2_ID, N'You should wash your hands before meals', 1),
(@Q2_ID, N'You should not eat too much candy', 1),

-- Unit 20: Tương lai gần
(@Q2_ID, N'I am going to visit Ha Long Bay this summer', 1),
(@Q2_ID, N'We are going to build a sandcastle on the beach', 1);

PRINT N'=== Đã tạo kho 20 câu hỏi cho Game Round 2 (Sắp xếp câu) thành công ===';
GO


-- 1. LẤY ID CỦA CÂU HỎI TRONG ROUND 2
DECLARE @Topic2ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Game Round 2 Pool');
DECLARE @Q2_ID INT = (SELECT TOP 1 QuestionID FROM Questions WHERE TopicID = @Topic2ID AND QuestionType = 'scramble');

-- Kiểm tra nếu chưa có ID thì báo lỗi (Thường là đã có do các bước trước)
IF @Q2_ID IS NULL
BEGIN
    PRINT N'❌ LỖI: Không tìm thấy câu hỏi Round 2. Vui lòng chạy lại script tạo cấu trúc Round 2 trước.';
    RETURN;
END

-- 2. XÓA DỮ LIỆU CŨ (Để đảm bảo sạch sẽ, không bị trùng)
DELETE FROM QuestionOptions WHERE QuestionID = @Q2_ID;
PRINT N'🧹 Đã dọn sạch dữ liệu cũ của Round 2.';

-- 3. CHÈN 20 CÂU MỚI VÀO
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
-- Unit 1: Giới thiệu bản thân
(@Q2_ID, N'I am a pupil at Nguyen Du Primary School', 1),
(@Q2_ID, N'I live with my parents in Hanoi', 1),

-- Unit 2: Nhà cửa
(@Q2_ID, N'My family lives on the third floor of Tower B', 1),
(@Q2_ID, N'It is a small and quiet village', 1),

-- Unit 4: Hoạt động rảnh rỗi
(@Q2_ID, N'I often surf the Internet in my free time', 1),
(@Q2_ID, N'She goes swimming twice a week', 1),

-- Unit 5: Nghề nghiệp
(@Q2_ID, N'I would like to be a writer in the future', 1),
(@Q2_ID, N'Why would you like to be a pilot', 1),

-- Unit 6: Trường học
(@Q2_ID, N'The library is on the first floor', 1),
(@Q2_ID, N'Go along the corridor and turn left', 1),

-- Unit 8: Lớp học
(@Q2_ID, N'May I write on the board', 1),
(@Q2_ID, N'Please do not talk in the class', 1),

-- Unit 9: Thì hiện tại tiếp diễn
(@Q2_ID, N'They are playing badminton in the playground', 1),
(@Q2_ID, N'What is he doing now', 1),

-- Unit 12: Ngày Tết
(@Q2_ID, N'We decorate our house before Tet', 1),
(@Q2_ID, N'I get lucky money from my grandparents', 1),

-- Unit 14: Sức khỏe
(@Q2_ID, N'You should wash your hands before meals', 1),
(@Q2_ID, N'You should not eat too much candy', 1),

-- Unit 20: Tương lai gần
(@Q2_ID, N'I am going to visit Ha Long Bay this summer', 1),
(@Q2_ID, N'We are going to build a sandcastle on the beach', 1);

PRINT N'✅ Đã nạp thành công 20 câu hỏi cho Round 2!';
GO

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