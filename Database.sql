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


-- 2. Tạo tài khoản đăng nhập vào Server (Tên: GameUser, Mật khẩu: 123456)
-- Lệnh này tự động BỎ QUA chính sách mật khẩu phức tạp
CREATE LOGIN GameUser WITH PASSWORD = '123456', CHECK_POLICY = OFF;


-- 3. Tạo User trong Database từ tài khoản trên
CREATE USER GameUser FOR LOGIN GameUser;


-- 4. Cấp quyền Đọc (Select) và Ghi (Insert/Update) cho User này
ALTER ROLE db_datareader ADD MEMBER GameUser;
ALTER ROLE db_datawriter ADD MEMBER GameUser;


-- 5. Đảm bảo Server cho phép đăng nhập bằng tài khoản SQL (Mixed Mode)
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
    N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;


PRINT '=== TẠO TÀI KHOẢN THÀNH CÔNG ===';
PRINT 'User: GameUser';
PRINT 'Pass: 123456';
SELECT @@SERVERNAME;
-- Sử dụng database vừa tạo
USE GameHocTiengAnh1;


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
    TopicName NVARCHAR(100) NOT NULL,
    GradeID INT, -- Thêm cột này
    FOREIGN KEY (GradeID) REFERENCES Grades(GradeID)
);

-- Bảng Từ vựng
CREATE TABLE Vocabulary (
    VocabID INT PRIMARY KEY IDENTITY(1,1),
    Word NVARCHAR(100) NOT NULL,
    WordType NVARCHAR(50), 
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
    GrammarName NVARCHAR(150) NOT NULL, 
    Structure NVARCHAR(MAX),            
    Usage NVARCHAR(MAX),                
    Example NVARCHAR(MAX),              
    TopicID INT,                        
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
    TimeLimit INT DEFAULT 0,  
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

-- Bảng Lịch sử chơi game (Cấu trúc mới chuẩn cho Leaderboard)
CREATE TABLE PlayHistory (
    HistoryID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT NOT NULL,
    GameID INT NOT NULL,
    TopicID INT,            -- [MỚI] Để biết chơi bài nào
    Score INT NOT NULL,
    TimeTaken INT,          -- Thời gian chơi (giây)
    Difficulty NVARCHAR(50),-- [MỚI] Lưu độ khó (Easy/Normal/Hard)
    PlayedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (StudentID) REFERENCES Users(UserID),
    FOREIGN KEY (GameID) REFERENCES Games(GameID),
    FOREIGN KEY (TopicID) REFERENCES Topics(TopicID),
    CONSTRAINT CK_Score_Positive CHECK (Score >= 0)
);

-- Index giúp lọc lịch sử nhanh hơn cho Leaderboard
CREATE INDEX IX_PlayHistory_Leaderboard ON PlayHistory(TopicID, Difficulty, Score DESC, TimeTaken ASC);
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


USE GameHocTiengAnh1;


-- 1. Tạo Topic riêng cho Game Round 2
INSERT INTO Topics (TopicName) VALUES (N'Game Round 2 Pool');
DECLARE @GameTopic2ID INT = SCOPE_IDENTITY(); -- Lấy ID vừa tạo

-- 2. Tạo 1 câu hỏi "Container" chứa danh sách các câu cần sắp xếp
-- QuestionType vẫn là 'scramble' (sắp xếp)
INSERT INTO Questions (TopicID, QuestionText, QuestionType, HintText, CorrectAnswer)
VALUES (@GameTopic2ID, N'Sắp xếp các từ xáo trộn thành câu hoàn chỉnh', 'scramble', N'Game Round 2', N'All Sentences');

DECLARE @Q2_ID INT = SCOPE_IDENTITY();

-- ==========================================================
--TẠO KHUNG CHỦ ĐỀ CHO CẢ 9 UNIT (0 - 8)
-- ==========================================================
-- BƯỚC 2: TẠO KHUNG CHỦ ĐỀ CHO CẢ 9 UNIT (0 - 8) - GẮN VÀO LỚP 5
-- ==========================================================

-- Lấy ID của Khối 5
DECLARE @Grade5ID INT = (SELECT GradeID FROM Grades WHERE GradeName = N'Khối 5');

-- Chèn dữ liệu (Bao gồm Tên + GradeID)
INSERT INTO Topics (TopicName, GradeID) VALUES 
    (N'Unit 0: Getting Started', @Grade5ID),
    (N'Unit 1: Animal Habitats', @Grade5ID),
    (N'Unit 2: Let''s Eat!', @Grade5ID),
    (N'Unit 3: On the Move!', @Grade5ID),
    (N'Unit 4: Our Senses', @Grade5ID),
    (N'Unit 5: Our Health', @Grade5ID),
    (N'Unit 6: The World of School', @Grade5ID),
    (N'Unit 7: The World of Work', @Grade5ID),
    (N'Unit 8: Fantastic Holidays and Festivals', @Grade5ID);


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
    (N'Sử dụng bộ phận cơ thể (Use... to)', N'[Animals] use their [Body Part] to [Action].', N'Mô tả chức năng bộ phận cơ thể.', N'Giraffes use their long tongues to clean their ears. ats use their horns to fight.', @Unit1ID);


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


UPDATE Topics SET TopicName = N'Unit 3: On the Move!' WHERE TopicName LIKE N'Unit 3%';
UPDATE Topics SET TopicName = N'Unit 4: Our Senses' WHERE TopicName LIKE N'Unit 4%';
UPDATE Topics SET TopicName = N'Unit 5: Our Health' WHERE TopicName LIKE N'Unit 5%';
UPDATE Topics SET TopicName = N'Unit 6: The World of School' WHERE TopicName LIKE N'Unit 6%';
UPDATE Topics SET TopicName = N'Unit 7: The World of Work' WHERE TopicName LIKE N'Unit 7%';
UPDATE Topics SET TopicName = N'Unit 8: Fantastic Holidays and Festivals' WHERE TopicName LIKE N'Unit 8%';


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
     N'Q: Do you  to school by [Vehicle]?
A: No, I don''t. I  to school [by Vehicle / on foot].', 
     N'Hỏi cách di chuyển đến trường.', 
     N'Do you  to school by bus? No, I don''t. I  to school on foot.', @Unit3ID),
    
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
    (' on a field trip', N'đi dã nại thực tế', 'Phrase', @Unit6ID),
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
     N'Q: Where did you  [Time]?
A: I went to [Place].
Q: Why did you  to the [Place]?
A: We went there to [Purpose].', 
     N'Hỏi địa điểm và lý do đi đâu đó.', 
     N'Where did you  last summer? I went to a zoo. Why? We went there to learn about animals.', @Unit6ID);


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
A: Sure.  straight and then turn [left/right]. It''s on your [left/right].', 
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
    (@Q_ID, N'{"L": "ats use their horns", "R": "to fight."}', 1),
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
    (@Q_ID, N'{"L": "How do you  to school?", "R": "I  by bus."}', 1),
    (@Q_ID, N'{"L": "Do you  by car?", "R": "No, I  on foot."}', 1),
    (@Q_ID, N'{"L": "How often do you ride a bike?", "R": "Twice a week."}', 1),
    (@Q_ID, N'{"L": "Does he drive to work?", "R": "Yes, he does."}', 1),
    (@Q_ID, N'{"L": "I ride my scooter", "R": "to the park."}', 1),
    (@Q_ID, N'{"L": "My father drives", "R": "me to school."}', 1),
    (@Q_ID, N'{"L": "We take the ferry", "R": "across the river."}', 1),
    (@Q_ID, N'{"L": "I never ", "R": "by helicopter."}', 1);
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
    (@Q_ID, N'{"L": "Field trip", "R": "Chuyến dã nại"}', 1),
    (@Q_ID, N'{"L": "Poster", "R": "Áp phích"}', 1),
    (@Q_ID, N'{"L": "Club", "R": "Câu lạc bộ"}', 1),
    (@Q_ID, N'{"L": "Board games", "R": "Trò chơi bàn cờ"}', 1),
    (@Q_ID, N'{"L": "Read books", "R": "Đọc sách"}', 1),
    -- GRAMMAR (8)
    (@Q_ID, N'{"L": "What classes did you have?", "R": "I had Math and Art."}', 1),
    (@Q_ID, N'{"L": "When did you have Music?", "R": "On Tuesday."}', 1),
    (@Q_ID, N'{"L": "Where did you ?", "R": "I went to the zoo."}', 1),
    (@Q_ID, N'{"L": "Why did you  there?", "R": "To learn about animals."}', 1),
    (@Q_ID, N'{"L": "I made a poster", "R": "for my project."}', 1),
    (@Q_ID, N'{"L": "We joined", "R": "a science club."}', 1),
    (@Q_ID, N'{"L": "Did you  on", "R": "a field trip?"}', 1),
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
    (@Q_ID, N'{"L": " straight and", "R": "turn left."}', 1),
    (@Q_ID, N'{"L": "It is on", "R": "your right."}', 1),
    (@Q_ID, N'{"L": "What will you do?", "R": "I will buy souvenirs."}', 1),
    (@Q_ID, N'{"L": "I will light", "R": "lanterns."}', 1),
    (@Q_ID, N'{"L": "We will watch", "R": "a lion dance."}', 1),
    (@Q_ID, N'{"L": "Mid-Autumn Festival", "R": "is next week."}', 1),
    (@Q_ID, N'{"L": "Where will you ?", "R": "I will  to the beach."}', 1);
END

DELETE FROM QuestionOptions WHERE QuestionID IN (SELECT QuestionID FROM Questions WHERE QuestionType = 'scramble');
DELETE FROM Questions WHERE QuestionType = 'scramble';
PRINT N'🧹 Đã dọn dẹp dữ liệu Scramble cũ.';
go
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
    (@Q_ID, N'We often  swimming in summer', 1),
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
    (@Q_ID, N'ats use their horns to fight', 1),
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
    (@Q_ID, N'Do you  to school by bus', 1),
    (@Q_ID, N'No I  to school on foot', 1),
    (@Q_ID, N'My father drives to work', 1),
    (@Q_ID, N'How often do you ride your bike', 1),
    (@Q_ID, N'I ride my bike twice a week', 1),
    (@Q_ID, N'We took a ferry across the river', 1),
    (@Q_ID, N'The subway is very fast', 1),
    (@Q_ID, N'Have you ever flown in a helicopter', 1),
    (@Q_ID, N'I ride my scooter in the park', 1),
    (@Q_ID, N'He es to school by motorcycle', 1),
    (@Q_ID, N'We are ing to travel by airplane', 1),
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
    (@Q_ID, N'Eating vegetables is od for health', 1),
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
    (@Q_ID, N'Where did you  last summer', 1),
    (@Q_ID, N'I went on a field trip to the zoo', 1),
    (@Q_ID, N'Why did you  to the zoo', 1),
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
    (@Q_ID, N' straight and turn left', 1),
    (@Q_ID, N'It is on your right', 1),
    (@Q_ID, N'The Mid Autumn Festival is next week', 1),
    (@Q_ID, N'What will you do there', 1),
    (@Q_ID, N'I will light lanterns', 1),
    (@Q_ID, N'We will watch a lion dance', 1),
    (@Q_ID, N'I will  to my grandma house', 1),
    (@Q_ID, N'We will eat lots of mooncakes', 1),
    (@Q_ID, N'I will wear a costume for Halloween', 1),
    (@Q_ID, N'We will visit a theme park', 1),
    (@Q_ID, N'I am ing to buy souvenirs', 1),
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

USE GameHocTiengAnh1;

PRINT N'=== BẮT ĐẦU TẠO DỮ LIỆU ROUND 3 (TRẮC NGHIỆM) ===';

-- 1. DỌN DẸP DỮ LIỆU ROUND 3 CŨ (Để tránh trùng lặp)
DELETE FROM QuestionOptions WHERE QuestionID IN (SELECT QuestionID FROM Questions WHERE QuestionType = 'multiple_choice');
DELETE FROM Questions WHERE QuestionType = 'multiple_choice';
PRINT N'🧹 Đã xóa câu hỏi trắc nghiệm cũ.';

-- 2. TẠO THỦ TỤC TẠM ĐỂ CHÈN CÂU HỎI NHANH (Giúp code ngắn gọn)
IF OBJECT_ID('tempdb..#AddQuiz') IS NOT NULL DROP PROCEDURE #AddQuiz;


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
EXEC #AddQuiz N'Unit 1', N'ats use their horns to ______.', N'fight', N'fly', N'swim', N'sing';
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
EXEC #AddQuiz N'Unit 3', N'How do you  to school?', N'By bus', N'On bus', N'In bus', N'At bus';
EXEC #AddQuiz N'Unit 3', N'We  to the park ______ foot.', N'on', N'by', N'in', N'with';
EXEC #AddQuiz N'Unit 3', N'Does your father ______ a car?', N'drive', N'ride', N'fly', N'sail';
EXEC #AddQuiz N'Unit 3', N'I ______ my bike to school.', N'ride', N'drive', N'fly', N'run';
EXEC #AddQuiz N'Unit 3', N'A ______ flies in the sky.', N'helicopter', N'boat', N'train', N'subway';
EXEC #AddQuiz N'Unit 3', N'The ______ runs underground.', N'subway', N'bus', N'taxi', N'airplane';
EXEC #AddQuiz N'Unit 3', N'We took a ______ across the river.', N'ferry', N'bike', N'car', N'train';
EXEC #AddQuiz N'Unit 3', N'He es to work ______ motorcycle.', N'by', N'on', N'in', N'at';
EXEC #AddQuiz N'Unit 3', N'______ often do you ride your bike?', N'How', N'What', N'Where', N'When';
EXEC #AddQuiz N'Unit 3', N'I ride my scooter ______ a week.', N'twice', N'two', N'second', N'twelve';
EXEC #AddQuiz N'Unit 3', N'Cars must stop at the ______ light.', N'red', N'green', N'yellow', N'blue';
EXEC #AddQuiz N'Unit 3', N'A pilot flies an ______.', N'airplane', N'bus', N'boat', N'taxi';
EXEC #AddQuiz N'Unit 3', N'Please ______ on the bus.', N'get', N'', N'take', N'make';
EXEC #AddQuiz N'Unit 3', N'We get ______ the train at the station.', N'off', N'out', N'up', N'down';
EXEC #AddQuiz N'Unit 3', N'It is safe to walk on the ______.', N'sidewalk', N'street', N'road', N'river';
EXEC #AddQuiz N'Unit 3', N'Do you ever  by helicopter?', N'No, never.', N'Yes, I am.', N'No, I don''t.', N'Yes, it is.';
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
EXEC #AddQuiz N'Unit 4', N'The garbage smelled ______.', N'bad', N'od', N'beautiful', N'soft';
EXEC #AddQuiz N'Unit 4', N'The library is very ______.', N'quiet', N'loud', N'spicy', N'hard';
EXEC #AddQuiz N'Unit 4', N'I can ______ the birds singing.', N'hear', N'smell', N'touch', N'taste';
EXEC #AddQuiz N'Unit 4', N'This pillow feels ______.', N'soft', N'hard', N'loud', N'sour';
EXEC #AddQuiz N'Unit 4', N'Smoke smells like ______ wood.', N'burnt', N'sweet', N'soft', N'juicy';
EXEC #AddQuiz N'Unit 4', N'Durian has a strong ______.', N'smell', N'sound', N'look', N'feel';
EXEC #AddQuiz N'Unit 4', N'These chips are too ______.', N'salty', N'loud', N'quiet', N'soft';
EXEC #AddQuiz N'Unit 4', N'How does the cake taste?', N'It tastes sweet.', N'It sounds sweet.', N'It looks loud.', N'It feels spicy.';
EXEC #AddQuiz N'Unit 4', N'Did you touch the snake?', N'Yes, it felt cold.', N'Yes, it smelled od.', N'No, it was loud.', N'Yes, it tasted sweet.';
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
EXEC #AddQuiz N'Unit 5', N'You should ______ exercise every day.', N'do', N'make', N'play', N'';
EXEC #AddQuiz N'Unit 5', N'My stomachache is getting ______.', N'worse', N'bad', N'od', N'better';
EXEC #AddQuiz N'Unit 5', N'I have a ______ nose.', N'runny', N'running', N'rainy', N'sunny';
EXEC #AddQuiz N'Unit 5', N'You should rest your ______.', N'eyes', N'ears', N'mouth', N'nose';
EXEC #AddQuiz N'Unit 5', N'Eating vegetables is ______ for health.', N'od', N'bad', N'wrong', N'sick';
EXEC #AddQuiz N'Unit 5', N'Drink plenty of ______.', N'water', N'soda', N'oil', N'coffee';
EXEC #AddQuiz N'Unit 5', N'Did you take the medicine?', N'Yes, I did.', N'Yes, I do.', N'No, I don''t.', N'Yes, I am.';
EXEC #AddQuiz N'Unit 5', N'I feel much ______ now.', N'better', N'od', N'well', N'bad';
EXEC #AddQuiz N'Unit 5', N'You shouldn''t stay up ______.', N'late', N'early', N'morning', N'noon';


PRINT N'--- Đang nạp Unit 6: The World of School ---';
EXEC #AddQuiz N'Unit 6', N'What ______ did you have last week?', N'classes', N'class', N'school', N'lesson';
EXEC #AddQuiz N'Unit 6', N'I ______ math and literature.', N'had', N'have', N'has', N'having';
EXEC #AddQuiz N'Unit 6', N'______ did you have music class?', N'When', N'Where', N'What', N'Who';
EXEC #AddQuiz N'Unit 6', N'I had music ______ Tuesday.', N'on', N'in', N'at', N'of';
EXEC #AddQuiz N'Unit 6', N'Where did you  last summer?', N'I went to the zoo.', N'I  to the zoo.', N'I ing to the zoo.', N'I es to the zoo.';
EXEC #AddQuiz N'Unit 6', N'I went on a ______ trip.', N'field', N'school', N'class', N'home';
EXEC #AddQuiz N'Unit 6', N'Why did you  to the zoo?', N'To learn about animals.', N'To buy food.', N'To sleep.', N'To swim.';
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
EXEC #AddQuiz N'Unit 6', N'We usually ______ sports after school.', N'play', N'do', N'make', N'';
EXEC #AddQuiz N'Unit 6', N'Did you make a video?', N'Yes, I did.', N'Yes, I do.', N'No, I don''t.', N'Yes, I am.';
EXEC #AddQuiz N'Unit 6', N'Art is about ______.', N'drawing', N'singing', N'running', N'counting';


PRINT N'--- Đang nạp Unit 7: The World of Work ---';
EXEC #AddQuiz N'Unit 7', N'What do you want to ______ one day?', N'be', N'do', N'make', N'have';
EXEC #AddQuiz N'Unit 7', N'I want to be a ______.', N'salesperson', N'sell', N'selling', N'sold';
EXEC #AddQuiz N'Unit 7', N'I will ______ delicious foods.', N'sell', N'buy', N'eat', N'drink';
EXEC #AddQuiz N'Unit 7', N'Why do you like this singer?', N'Because she sings beautifully.', N'Because she runs fast.', N'Because she cooks well.', N'Because she builds houses.';
EXEC #AddQuiz N'Unit 7', N'A builder ______ houses.', N'builds', N'makes', N'does', N'creates';
EXEC #AddQuiz N'Unit 7', N'A tailor ______ clothes.', N'makes', N'wears', N'buys', N'sells';
EXEC #AddQuiz N'Unit 7', N'The athlete runs very ______.', N'fast', N'slow', N'od', N'bad';
EXEC #AddQuiz N'Unit 7', N'A flight attendant works on a ______.', N'plane', N'bus', N'train', N'ship';
EXEC #AddQuiz N'Unit 7', N'The magician ______ magic tricks.', N'performs', N'plays', N'does', N'makes';
EXEC #AddQuiz N'Unit 7', N'A mechanic ______ cars.', N'repairs', N'drives', N'rides', N'buys';
EXEC #AddQuiz N'Unit 7', N'A dentist looks after your ______.', N'teeth', N'eyes', N'ears', N'hands';
EXEC #AddQuiz N'Unit 7', N'I want to help ______ people.', N'sick', N'healthy', N'rich', N'poor';
EXEC #AddQuiz N'Unit 7', N'He works very ______.', N'hard', N'hardly', N'od', N'bad';
EXEC #AddQuiz N'Unit 7', N'My mother is a ______.', N'teacher', N'teach', N'teaching', N'taught';
EXEC #AddQuiz N'Unit 7', N'The musician plays the ______ well.', N'guitar', N'football', N'tennis', N'game';
EXEC #AddQuiz N'Unit 7', N'A babysitter looks ______ children.', N'after', N'at', N'for', N'up';
EXEC #AddQuiz N'Unit 7', N'What does your father do?', N'He is a police officer.', N'He is kind.', N'He likes football.', N'He is at home.';
EXEC #AddQuiz N'Unit 7', N'I respect everyone''s ______.', N'jobs', N'hobbies', N'names', N'houses';
EXEC #AddQuiz N'Unit 7', N'A salesperson works in a ______.', N'shop', N'hospital', N'school', N'park';
EXEC #AddQuiz N'Unit 7', N'An artist paints ______.', N'pictures', N'houses', N'walls', N'cars';


PRINT N'--- Đang nạp Unit 8: Fantastic Holidays ---';
EXEC #AddQuiz N'Unit 8', N'Could you show me the way to the ______?', N'market', N'mark', N'marketing', N'marked';
EXEC #AddQuiz N'Unit 8', N' ______ and turn left.', N'straight', N'street', N'long', N'short';
EXEC #AddQuiz N'Unit 8', N'It is on your ______.', N'right', N'write', N'white', N'light';
EXEC #AddQuiz N'Unit 8', N'The Mid-Autumn Festival is next ______.', N'week', N'day', N'month', N'year';
EXEC #AddQuiz N'Unit 8', N'What ______ you do there?', N'will', N'do', N'did', N'does';
EXEC #AddQuiz N'Unit 8', N'I will ______ lanterns.', N'light', N'see', N'watch', N'look';
EXEC #AddQuiz N'Unit 8', N'We will watch a ______ dance.', N'lion', N'tiger', N'cat', N'dog';
EXEC #AddQuiz N'Unit 8', N'I will  to my grandma''s ______.', N'house', N'home', N'school', N'work';
EXEC #AddQuiz N'Unit 8', N'We will eat lots of ______.', N'mooncakes', N'pizza', N'burgers', N'rice';
EXEC #AddQuiz N'Unit 8', N'I will wear a ______ for Halloween.', N'costume', N'uniform', N'dress', N'shirt';
EXEC #AddQuiz N'Unit 8', N'We will visit a ______ park.', N'theme', N'team', N'time', N'term';
EXEC #AddQuiz N'Unit 8', N'I am ing to buy ______.', N'souvenirs', N'gifts', N'presents', N'toys';
EXEC #AddQuiz N'Unit 8', N'Where is the ______?', N'waterfall', N'water', N'falling', N'fell';
EXEC #AddQuiz N'Unit 8', N'We will stay at a ______.', N'resort', N'hotel', N'home', N'house';
EXEC #AddQuiz N'Unit 8', N'Children get ______ money at Tet.', N'lucky', N'happy', N'od', N'bad';
EXEC #AddQuiz N'Unit 8', N'We clean our house ______ Tet.', N'before', N'after', N'during', N'when';
EXEC #AddQuiz N'Unit 8', N'Do you like Christmas?', N'Yes, I do.', N'Yes, I am.', N'No, I am not.', N'Yes, it is.';
EXEC #AddQuiz N'Unit 8', N'We will have a ______ time.', N'great', N'bad', N'sad', N'boring';
EXEC #AddQuiz N'Unit 8', N'Turn right at the ______ shop.', N'souvenir', N'book', N'food', N'clothes';
EXEC #AddQuiz N'Unit 8', N'I am excited ______ the holidays.', N'for', N'with', N'at', N'in';

-- XÓA THỦ TỤC TẠM
DROP PROCEDURE #AddQuiz;

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU TRẮC NGHIỆM (20 CÂU x 9 UNIT)!';


IF OBJECT_ID('tempdb..#AddFillBlank') IS NOT NULL DROP PROCEDURE #AddFillBlank;


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


-- NẠP DỮ LIỆU (20 CÂU/UNIT)

PRINT N'--- Unit 0: Getting Started ---';
EXEC #AddFillBlank N'Unit 0', N'The weather is hot in ______.', N'summer', N'winter', N'spring', N'fall';
EXEC #AddFillBlank N'Unit 0', N'Leaves fall from trees in ______.', N'autumn', N'summer', N'spring', N'winter';
EXEC #AddFillBlank N'Unit 0', N'It is ______ and snowy in winter.', N'cold', N'hot', N'warm', N'dry';
EXEC #AddFillBlank N'Unit 0', N'There are twelve ______ in a year.', N'months', N'weeks', N'days', N'seasons';
EXEC #AddFillBlank N'Unit 0', N'My birthday is ______ May.', N'in', N'on', N'at', N'of';
EXEC #AddFillBlank N'Unit 0', N'What is the weather ______ today?', N'like', N'is', N'look', N'love';
EXEC #AddFillBlank N'Unit 0', N'Ten plus ten is ______.', N'twenty', N'thirty', N'ten', N'forty';
EXEC #AddFillBlank N'Unit 0', N'I like to  swimming in the ______ season.', N'dry', N'rainy', N'cold', N'snowy';
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
EXEC #AddFillBlank N'Unit 1', N'ats have two ______ on their heads.', N'horns', N'tails', N'noses', N'wings';
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
EXEC #AddFillBlank N'Unit 3', N'I  to school ______ bus.', N'by', N'on', N'in', N'at';
EXEC #AddFillBlank N'Unit 3', N'We walk on the ______.', N'sidewalk', N'street', N'road', N'river';
EXEC #AddFillBlank N'Unit 3', N'My father ______ a car to work.', N'drives', N'rides', N'flies', N'walks';
EXEC #AddFillBlank N'Unit 3', N'I ______ my bicycle in the park.', N'ride', N'drive', N'run', N'fly';
EXEC #AddFillBlank N'Unit 3', N'A ______ flies in the sky.', N'plane', N'bus', N'train', N'boat';
EXEC #AddFillBlank N'Unit 3', N'The ______ runs on tracks.', N'train', N'car', N'bus', N'taxi';
EXEC #AddFillBlank N'Unit 3', N'We took a ______ across the river.', N'ferry', N'bike', N'scooter', N'truck';
EXEC #AddFillBlank N'Unit 3', N'You must ______ at the red light.', N'stop', N'', N'run', N'walk';
EXEC #AddFillBlank N'Unit 3', N'Always wear a ______ on a motorbike.', N'helmet', N'hat', N'cap', N'mask';
EXEC #AddFillBlank N'Unit 3', N'The subway es ______ ground.', N'under', N'on', N'above', N'in';
EXEC #AddFillBlank N'Unit 3', N'We get ______ the bus at the station.', N'off', N'out', N'away', N'over';
EXEC #AddFillBlank N'Unit 3', N'How ______ do you ride your bike?', N'often', N'many', N'much', N'time';
EXEC #AddFillBlank N'Unit 3', N'I  to school on ______.', N'foot', N'leg', N'hand', N'head';
EXEC #AddFillBlank N'Unit 3', N'Boats ______ on water.', N'sail', N'drive', N'ride', N'run';
EXEC #AddFillBlank N'Unit 3', N'A helicopter has ______ on top.', N'blades', N'wings', N'wheels', N'doors';
EXEC #AddFillBlank N'Unit 3', N'Is it safe? - Yes, it ______.', N'is', N'isn''t', N'does', N'do';
EXEC #AddFillBlank N'Unit 3', N'Traffic lights have ______ colors.', N'three', N'two', N'four', N'five';
EXEC #AddFillBlank N'Unit 3', N'Green light means ______.', N'', N'stop', N'wait', N'slow';
EXEC #AddFillBlank N'Unit 3', N'I sit ______ the car.', N'in', N'on', N'at', N'under';
EXEC #AddFillBlank N'Unit 3', N'He es to work ______ motorcycle.', N'by', N'in', N'with', N'at';

PRINT N'--- Unit 4: Our Senses ---';
EXEC #AddFillBlank N'Unit 4', N'I use my ______ to see.', N'eyes', N'ears', N'nose', N'mouth';
EXEC #AddFillBlank N'Unit 4', N'I use my ______ to hear.', N'ears', N'eyes', N'hands', N'legs';
EXEC #AddFillBlank N'Unit 4', N'I use my nose to ______.', N'smell', N'taste', N'touch', N'look';
EXEC #AddFillBlank N'Unit 4', N'The rabbit feels ______.', N'soft', N'hard', N'loud', N'quiet';
EXEC #AddFillBlank N'Unit 4', N'The rock feels ______.', N'hard', N'soft', N'sweet', N'sour';
EXEC #AddFillBlank N'Unit 4', N'The music is too ______.', N'loud', N'soft', N'tasty', N'smelly';
EXEC #AddFillBlank N'Unit 4', N'The flowers look ______.', N'beautiful', N'ugly', N'loud', N'quiet';
EXEC #AddFillBlank N'Unit 4', N'The garbage smells ______.', N'bad', N'od', N'nice', N'sweet';
EXEC #AddFillBlank N'Unit 4', N'The lemon tastes ______.', N'sour', N'salty', N'spicy', N'hot';
EXEC #AddFillBlank N'Unit 4', N'Did you ______ the thunder?', N'hear', N'smell', N'touch', N'taste';
EXEC #AddFillBlank N'Unit 4', N'The rainbow looks ______.', N'colorful', N'loud', N'bad', N'tasty';
EXEC #AddFillBlank N'Unit 4', N'Smoke smells like ______ wood.', N'burnt', N'fresh', N'clean', N'sweet';
EXEC #AddFillBlank N'Unit 4', N'Durian has a strong ______.', N'smell', N'sound', N'look', N'touch';
EXEC #AddFillBlank N'Unit 4', N'Please be ______ in the library.', N'quiet', N'loud', N'noisy', N'fast';
EXEC #AddFillBlank N'Unit 4', N'I touch with my ______.', N'hands', N'eyes', N'ears', N'nose';
EXEC #AddFillBlank N'Unit 4', N'The drum sounds ______.', N'loud', N'soft', N'quiet', N'bad';
EXEC #AddFillBlank N'Unit 4', N'Does it taste od? - Yes, it ______.', N'does', N'is', N'do', N'are';
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
EXEC #AddFillBlank N'Unit 5', N'Exercise is ______ for you.', N'od', N'bad', N'sad', N'sick';
EXEC #AddFillBlank N'Unit 5', N'I ______ feel well.', N'don''t', N'not', N'am', N'isn''t';
EXEC #AddFillBlank N'Unit 5', N'Did you ______ the medicine?', N'take', N'eat', N'drink', N'';
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
EXEC #AddFillBlank N'Unit 6', N'I went to the ______ yesterday.', N'zoo', N'', N'es', N'ing';
EXEC #AddFillBlank N'Unit 6', N'Did you ______ a video?', N'make', N'do', N'play', N'';
EXEC #AddFillBlank N'Unit 6', N'I use a ______ in IT class.', N'computer', N'ball', N'book', N'pen';
EXEC #AddFillBlank N'Unit 6', N'We learn about the past in ______.', N'history', N'math', N'music', N'art';
EXEC #AddFillBlank N'Unit 6', N'I draw pictures in ______ class.', N'art', N'math', N'PE', N'IT';
EXEC #AddFillBlank N'Unit 6', N'Our school has a big ______.', N'playground', N'play', N'playing', N'played';
EXEC #AddFillBlank N'Unit 6', N'My teacher is very ______.', N'kind', N'bad', N'angry', N'sad';
EXEC #AddFillBlank N'Unit 6', N'We wear a ______ at school.', N'uniform', N'costume', N'pyjama', N'hat';
EXEC #AddFillBlank N'Unit 6', N'I joined a science ______.', N'club', N'class', N'room', N'house';
EXEC #AddFillBlank N'Unit 6', N'What ______ do you have today?', N'subjects', N'games', N'toys', N'food';
EXEC #AddFillBlank N'Unit 6', N'I like to ______ the piano.', N'play', N'do', N'make', N'';
EXEC #AddFillBlank N'Unit 6', N'We eat lunch in the ______.', N'canteen', N'library', N'gym', N'lab';
EXEC #AddFillBlank N'Unit 6', N'I do my ______ after school.', N'homework', N'housework', N'play', N'sleep';
EXEC #AddFillBlank N'Unit 6', N'Did you  to school? - Yes, I ______.', N'did', N'do', N'does', N'done';
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
EXEC #AddFillBlank N'Unit 8', N'We will  to the ______.', N'beach', N'school', N'work', N'hospital';
EXEC #AddFillBlank N'Unit 8', N'I will ______ my grandma.', N'visit', N'see', N'watch', N'look';
EXEC #AddFillBlank N'Unit 8', N'We eat ______ cake at Mid-Autumn.', N'moon', N'sun', N'star', N'sky';
EXEC #AddFillBlank N'Unit 8', N'Children get lucky ______ at Tet.', N'money', N'candy', N'toy', N'book';
EXEC #AddFillBlank N'Unit 8', N'We will stay at a ______.', N'hotel', N'school', N'shop', N'park';
EXEC #AddFillBlank N'Unit 8', N' ______ and turn left.', N'straight', N'street', N'right', N'back';
EXEC #AddFillBlank N'Unit 8', N'The market is on your ______.', N'right', N'write', N'white', N'light';
EXEC #AddFillBlank N'Unit 8', N'I will buy some ______.', N'souvenirs', N'money', N'hotel', N'beach';
EXEC #AddFillBlank N'Unit 8', N'We decorate the house ______ Tet.', N'before', N'after', N'during', N'when';
EXEC #AddFillBlank N'Unit 8', N'Santa Claus comes at ______.', N'Christmas', N'Tet', N'Easter', N'Halloween';
EXEC #AddFillBlank N'Unit 8', N'We watch a ______ dance.', N'lion', N'tiger', N'cat', N'dog';
EXEC #AddFillBlank N'Unit 8', N'I will ______ a sandcastle.', N'build', N'make', N'do', N'';
EXEC #AddFillBlank N'Unit 8', N'Where ______ you ?', N'will', N'do', N'did', N'does';
EXEC #AddFillBlank N'Unit 8', N'It will be ______.', N'fun', N'sad', N'bad', N'boring';
EXEC #AddFillBlank N'Unit 8', N'I wear a ______ for Halloween.', N'costume', N'uniform', N'suit', N'dress';
EXEC #AddFillBlank N'Unit 8', N'We will swim in the ______.', N'sea', N'sky', N'sand', N'mountain';
EXEC #AddFillBlank N'Unit 8', N'Happy New ______!', N'Year', N'Day', N'Month', N'Week';
EXEC #AddFillBlank N'Unit 8', N'I am ing to ______ a trip.', N'take', N'do', N'make', N'';
EXEC #AddFillBlank N'Unit 8', N'See you ______ week.', N'next', N'last', N'past', N'before';
EXEC #AddFillBlank N'Unit 8', N'We travel by ______.', N'plane', N'foot', N'walk', N'run';

-- XÓA THỦ TỤC
DROP PROCEDURE #AddFillBlank;

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU ĐIỀN TỪ (20 CÂU x 9 UNIT)!';

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


PRINT N'✅ Đã tạo xong 4 Game Round (ID 1-4).';
go

USE GameHocTiengAnh1;
Go

PRINT N'=== BẮT ĐẦU NẠP DỮ LIỆU LỚP 2 CÁNH DIỀU (CẤU TRÚC INSERT TƯỜNG MINH - FULL DATA) ===';

-- =================================================================
-- KHAI BÁO BIẾN ID DÙNG CHUNG CHO TOÀN BỘ SCRIPT
-- =================================================================
DECLARE @TopicID INT;
DECLARE @QuestionID INT;

-- =================================================================
-- BƯỚC 1: DỌN DẸP DỮ LIỆU CŨ CỦA LỚP 2 (ĐỂ TRÁNH TRÙNG LẶP)
-- =================================================================
PRINT N'--- Đang dọn dẹp dữ liệu cũ ---';
-- Tạo bảng tạm chứa ID các chủ đề cần xóa
DECLARE @TopicsToDelete TABLE (ID INT);
INSERT INTO @TopicsToDelete SELECT TopicID FROM Topics WHERE TopicName LIKE N'Lớp 2 (CD)%';

-- Xóa dữ liệu từ bảng con đến bảng cha
DELETE FROM QuestionOptions WHERE QuestionID IN (SELECT QuestionID FROM Questions WHERE TopicID IN (SELECT ID FROM @TopicsToDelete));
DELETE FROM Questions WHERE TopicID IN (SELECT ID FROM @TopicsToDelete);
DELETE FROM Vocabulary WHERE TopicID IN (SELECT ID FROM @TopicsToDelete);
DELETE FROM Grammar WHERE TopicID IN (SELECT ID FROM @TopicsToDelete);
DELETE FROM Topics WHERE TopicID IN (SELECT ID FROM @TopicsToDelete);

PRINT N'✅ Đã dọn dẹp xong. Bắt đầu nạp dữ liệu mới...';


-- =================================================================
-- BƯỚC 2: NẠP DỮ LIỆU CHI TIẾT TỪNG UNIT
-- =================================================================

-- #################################################################
-- UNIT 0: GETTING STARTED
-- #################################################################
PRINT N'--- Nạp Unit 0 ---';
INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 2 (CD) - Unit 0: Getting Started',2);
SET @TopicID = SCOPE_IDENTITY();

-- === ROUND 1: MATCHING (Nối từ) ===
-- Tạo 1 câu hỏi "container"
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) 
VALUES (@TopicID, N'Nối từ vựng với nghĩa Tiếng Việt', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();

-- Chèn các cặp từ vào QuestionOptions
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Hello", "R": "Xin chào"}', 1),
(@QuestionID, N'{"L": "Hi", "R": "Chào (thân mật)"}', 1),
(@QuestionID, N'{"L": "odbye", "R": "Tạm biệt"}', 1),
(@QuestionID, N'{"L": "Bye", "R": "Tạm biệt (ngắn)"}', 1),
(@QuestionID, N'{"L": "Teacher", "R": "Giáo viên"}', 1),
(@QuestionID, N'{"L": "Class", "R": "Cả lớp"}', 1),
(@QuestionID, N'{"L": "Stand up", "R": "Đứng lên"}', 1),
(@QuestionID, N'{"L": "Sit down", "R": "Ngồi xuống"}', 1),
(@QuestionID, N'{"L": "Listen", "R": "Lắng nghe"}', 1),
(@QuestionID, N'{"L": "Open", "R": "Mở ra"}', 1),
(@QuestionID, N'{"L": "Close", "R": "Đóng lại"}', 1),
(@QuestionID, N'{"L": "One", "R": "Số 1"}', 1),
(@QuestionID, N'{"L": "Two", "R": "Số 2"}', 1),
(@QuestionID, N'{"L": "Three", "R": "Số 3"}', 1),
(@QuestionID, N'{"L": "Four", "R": "Số 4"}', 1),
(@QuestionID, N'{"L": "Five", "R": "Số 5"}', 1),
(@QuestionID, N'{"L": "Six", "R": "Số 6"}', 1),
(@QuestionID, N'{"L": "Seven", "R": "Số 7"}', 1),
(@QuestionID, N'{"L": "Eight", "R": "Số 8"}', 1),
(@QuestionID, N'{"L": "Nine", "R": "Số 9"}', 1),
(@QuestionID, N'{"L": "Ten", "R": "Số 10"}', 1),
(@QuestionID, N'{"L": "Red", "R": "Màu đỏ"}', 1),
(@QuestionID, N'{"L": "Blue", "R": "Màu xanh dương"}', 1),
(@QuestionID, N'{"L": "Yellow", "R": "Màu vàng"}', 1),
(@QuestionID, N'{"L": "Green", "R": "Màu xanh lá"}', 1),
(@QuestionID, N'{"L": "Black", "R": "Màu đen"}', 1),
(@QuestionID, N'{"L": "White", "R": "Màu trắng"}', 1);


-- === ROUND 2: SCRAMBLE (Sắp xếp câu) ===
-- Tạo 1 câu hỏi "container"
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) 
VALUES (@TopicID, N'Sắp xếp các từ thành câu hoàn chỉnh', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();

-- Chèn các câu cần sắp xếp vào QuestionOptions
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'Hello I am Kim', 1),
(@QuestionID, N'My name is Min', 1),
(@QuestionID, N'How are you', 1),
(@QuestionID, N'I am fine thank you', 1),
(@QuestionID, N'Stand up please', 1),
(@QuestionID, N'Sit down please', 1),
(@QuestionID, N'Open your book', 1),
(@QuestionID, N'Close your book', 1),
(@QuestionID, N'It is red', 1),
(@QuestionID, N'It is number one', 1),
(@QuestionID, N'I like blue', 1),
(@QuestionID, N'odbye teacher', 1),
(@QuestionID, N'See you later', 1),
(@QuestionID, N'What is your name', 1),
(@QuestionID, N'Listen to me', 1),
(@QuestionID, N'Hands up', 1),
(@QuestionID, N'Hands down', 1),
(@QuestionID, N'Be quiet please', 1),
(@QuestionID, N'I am seven years old', 1),
(@QuestionID, N'Nice to meet you', 1);


-- === ROUND 3: QUIZ (Trắc nghiệm) ===
-- Mỗi câu hỏi là một lần INSERT Questions và 4 lần INSERT Options
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'How are you?', 'multiple_choice', N'I am fine.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'I am fine.', 1), (@QuestionID, N'I am five.', 0), (@QuestionID, N'Hello.', 0), (@QuestionID, N'Bye.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What is it? (Image: Red)', 'multiple_choice', N'Red');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Red', 1), (@QuestionID, N'Blue', 0), (@QuestionID, N'One', 0), (@QuestionID, N'Two', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ up, please.', 'multiple_choice', N'Stand');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Stand', 1), (@QuestionID, N'Sit', 0), (@QuestionID, N'', 0), (@QuestionID, N'Do', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Hello, I ______ Lan.', 'multiple_choice', N'am');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'am', 1), (@QuestionID, N'is', 0), (@QuestionID, N'are', 0), (@QuestionID, N'it', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What number is it? (5)', 'multiple_choice', N'Five');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Five', 1), (@QuestionID, N'Four', 0), (@QuestionID, N'Six', 0), (@QuestionID, N'One', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sit ______.', 'multiple_choice', N'down');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'down', 1), (@QuestionID, N'up', 0), (@QuestionID, N'in', 0), (@QuestionID, N'on', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What color is the sun?', 'multiple_choice', N'Yellow');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yellow', 1), (@QuestionID, N'Green', 0), (@QuestionID, N'Black', 0), (@QuestionID, N'Purple', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Bye. See you ______.', 'multiple_choice', N'later');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'later', 1), (@QuestionID, N'now', 0), (@QuestionID, N'hello', 0), (@QuestionID, N'fine', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'One plus one is ______.', 'multiple_choice', N'two');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'two', 1), (@QuestionID, N'one', 0), (@QuestionID, N'three', 0), (@QuestionID, N'four', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I like ______ (màu đỏ).', 'multiple_choice', N'red');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'red', 1), (@QuestionID, N'bed', 0), (@QuestionID, N'fed', 0), (@QuestionID, N'blue', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What number is it? (1)', 'multiple_choice', N'One');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'One', 1), (@QuestionID, N'Two', 0), (@QuestionID, N'Three', 0), (@QuestionID, N'Ten', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What number is it? (3)', 'multiple_choice', N'Three');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Three', 1), (@QuestionID, N'Tree', 0), (@QuestionID, N'Free', 0), (@QuestionID, N'Ten', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is it red?', 'multiple_choice', N'Yes, it is.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yes, it is.', 1), (@QuestionID, N'Yes, I am.', 0), (@QuestionID, N'No, I am not.', 0), (@QuestionID, N'I like red.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'odbye ______.', 'multiple_choice', N'teacher');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'teacher', 1), (@QuestionID, N'book', 0), (@QuestionID, N'pen', 0), (@QuestionID, N'bag', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nice to ______ you.', 'multiple_choice', N'meet');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'meet', 1), (@QuestionID, N'meat', 0), (@QuestionID, N'met', 0), (@QuestionID, N'see', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'How ______ are you?', 'multiple_choice', N'old');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'old', 1), (@QuestionID, N'are', 0), (@QuestionID, N'is', 0), (@QuestionID, N'am', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I am ______ (6) years old.', 'multiple_choice', N'six');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'six', 1), (@QuestionID, N'seven', 0), (@QuestionID, N'five', 0), (@QuestionID, N'one', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is the color ______ (đen).', 'multiple_choice', N'black');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'black', 1), (@QuestionID, N'white', 0), (@QuestionID, N'red', 0), (@QuestionID, N'blue', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What color is the sky?', 'multiple_choice', N'Blue');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Blue', 1), (@QuestionID, N'Green', 0), (@QuestionID, N'Red', 0), (@QuestionID, N'Yellow', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ your book.', 'multiple_choice', N'Open');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Open', 1), (@QuestionID, N'Stand', 0), (@QuestionID, N'Sit', 0), (@QuestionID, N'', 0);


-- === ROUND 4: FILL IN BLANK (Điền từ) ===
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Stand ______.', 'fill_in_blank', N'up');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'up', 1), (@QuestionID, N'down', 0), (@QuestionID, N'in', 0), (@QuestionID, N'on', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sit ______.', 'fill_in_blank', N'down');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'down', 1), (@QuestionID, N'up', 0), (@QuestionID, N'left', 0), (@QuestionID, N'right', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My name ______ Lan.', 'fill_in_blank', N'is');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'is', 1), (@QuestionID, N'am', 0), (@QuestionID, N'are', 0), (@QuestionID, N'be', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I ______ fine.', 'fill_in_blank', N'am');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'am', 1), (@QuestionID, N'is', 0), (@QuestionID, N'are', 0), (@QuestionID, N'be', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is ______ (màu xanh).', 'fill_in_blank', N'blue');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'blue', 1), (@QuestionID, N'red', 0), (@QuestionID, N'one', 0), (@QuestionID, N'two', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is number ______ (3).', 'fill_in_blank', N'three');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'three', 1), (@QuestionID, N'tree', 0), (@QuestionID, N'free', 0), (@QuestionID, N'there', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ teacher.', 'fill_in_blank', N'odbye');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'odbye', 1), (@QuestionID, N'od', 0), (@QuestionID, N'Hello', 0), (@QuestionID, N'Hi', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Open your ______.', 'fill_in_blank', N'book');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'book', 1), (@QuestionID, N'hook', 0), (@QuestionID, N'look', 0), (@QuestionID, N'cook', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Close your ______.', 'fill_in_blank', N'book');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'book', 1), (@QuestionID, N'pen', 0), (@QuestionID, N'bag', 0), (@QuestionID, N'hand', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I am ______ (7) years old.', 'fill_in_blank', N'seven');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'seven', 1), (@QuestionID, N'six', 0), (@QuestionID, N'eight', 0), (@QuestionID, N'nine', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What ______ is it? - Red.', 'fill_in_blank', N'color');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'color', 1), (@QuestionID, N'name', 0), (@QuestionID, N'time', 0), (@QuestionID, N'day', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nice to ______ you.', 'fill_in_blank', N'meet');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'meet', 1), (@QuestionID, N'see', 0), (@QuestionID, N'look', 0), (@QuestionID, N'watch', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ hands.', 'fill_in_blank', N'Clap');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Clap', 1), (@QuestionID, N'Tap', 0), (@QuestionID, N'Nap', 0), (@QuestionID, N'Lap', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ to me.', 'fill_in_blank', N'Listen');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Listen', 1), (@QuestionID, N'Look', 0), (@QuestionID, N'Hear', 0), (@QuestionID, N'See', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is number ______ (5).', 'fill_in_blank', N'five');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'five', 1), (@QuestionID, N'four', 0), (@QuestionID, N'six', 0), (@QuestionID, N'one', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ are you? - I am fine.', 'fill_in_blank', N'How');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'How', 1), (@QuestionID, N'What', 0), (@QuestionID, N'Who', 0), (@QuestionID, N'Where', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is ______ (màu vàng).', 'fill_in_blank', N'yellow');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'yellow', 1), (@QuestionID, N'red', 0), (@QuestionID, N'blue', 0), (@QuestionID, N'black', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ me. (Nhìn tớ này)', 'fill_in_blank', N'Look');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Look', 1), (@QuestionID, N'Watch', 0), (@QuestionID, N'See', 0), (@QuestionID, N'Listen', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I like ______ (màu xanh lá).', 'fill_in_blank', N'green');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'green', 1), (@QuestionID, N'blue', 0), (@QuestionID, N'red', 0), (@QuestionID, N'black', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is it red? - No, it ______.', 'fill_in_blank', N'isn''t');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'isn''t', 1), (@QuestionID, N'is', 0), (@QuestionID, N'not', 0), (@QuestionID, N'aren''t', 0);



-- #################################################################
-- UNIT 1: MY CLASSROOM
-- #################################################################
PRINT N'--- Nạp Unit 1 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 1: My Classroom',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) 
VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Pencil", "R": "Bút chì"}', 1),
(@QuestionID, N'{"L": "Pen", "R": "Bút mực"}', 1),
(@QuestionID, N'{"L": "Crayon", "R": "Bút sáp"}', 1),
(@QuestionID, N'{"L": "Bag", "R": "Cặp sách"}', 1),
(@QuestionID, N'{"L": "Book", "R": "Sách"}', 1),
(@QuestionID, N'{"L": "Notebook", "R": "Vở"}', 1),
(@QuestionID, N'{"L": "Eraser", "R": "Tẩy"}', 1),
(@QuestionID, N'{"L": "Ruler", "R": "Thước kẻ"}', 1),
(@QuestionID, N'{"L": "Desk", "R": "Bàn học"}', 1),
(@QuestionID, N'{"L": "Chair", "R": "Ghế"}', 1),
(@QuestionID, N'{"L": "Board", "R": "Bảng"}', 1),
(@QuestionID, N'{"L": "Door", "R": "Cửa ra vào"}', 1),
(@QuestionID, N'{"L": "Window", "R": "Cửa sổ"}', 1),
(@QuestionID, N'{"L": "Pencil case", "R": "Hộp bút"}', 1),
(@QuestionID, N'{"L": "Backpack", "R": "Ba lô"}', 1),
(@QuestionID, N'{"L": "Computer", "R": "Máy tính"}', 1),
(@QuestionID, N'{"L": "Picture", "R": "Tranh"}', 1),
(@QuestionID, N'{"L": "Marker", "R": "Bút dạ"}', 1),
(@QuestionID, N'{"L": "Glue", "R": "Keo dán"}', 1),
(@QuestionID, N'{"L": "Scissors", "R": "Kéo"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) 
VALUES (@TopicID, N'Sắp xếp các từ thành câu hoàn chỉnh', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'It is a pencil', 1),
(@QuestionID, N'This is my bag', 1),
(@QuestionID, N'What is it', 1),
(@QuestionID, N'Is it a book', 1),
(@QuestionID, N'Yes it is', 1),
(@QuestionID, N'No it is not', 1),
(@QuestionID, N'Open the door', 1),
(@QuestionID, N'Close the window', 1),
(@QuestionID, N'Sit on the chair', 1),
(@QuestionID, N'Look at the board', 1),
(@QuestionID, N'It is an eraser', 1),
(@QuestionID, N'I have a pen', 1),
(@QuestionID, N'This is my desk', 1),
(@QuestionID, N'Is it a ruler', 1),
(@QuestionID, N'My bag is blue', 1),
(@QuestionID, N'My book is red', 1),
(@QuestionID, N'I like my school', 1),
(@QuestionID, N'It is a crayon', 1),
(@QuestionID, N'Where is my pen', 1),
(@QuestionID, N'The pencil is yellow', 1);

-- QUIZ
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What is it? (Pen)', 'multiple_choice', N'It is a pen.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'It is a pen.', 1), (@QuestionID, N'It is a bag.', 0), (@QuestionID, N'It is a dog.', 0), (@QuestionID, N'It is a cat.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is it a ruler?', 'multiple_choice', N'Yes, it is.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yes, it is.', 1), (@QuestionID, N'Yes, I do.', 0), (@QuestionID, N'No, I am not.', 0), (@QuestionID, N'I like rulers.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I sit on a ______.', 'multiple_choice', N'chair');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'chair', 1), (@QuestionID, N'desk', 0), (@QuestionID, N'board', 0), (@QuestionID, N'book', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is an ______ (cục tẩy).', 'multiple_choice', N'eraser');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'eraser', 1), (@QuestionID, N'pencil', 0), (@QuestionID, N'book', 0), (@QuestionID, N'ruler', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Open your ______.', 'multiple_choice', N'book');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'book', 1), (@QuestionID, N'pencil', 0), (@QuestionID, N'ruler', 0), (@QuestionID, N'chair', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What color is the bag?', 'multiple_choice', N'It is green.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'It is green.', 1), (@QuestionID, N'It is one.', 0), (@QuestionID, N'Yes, it is.', 0), (@QuestionID, N'It is a bag.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is this a bag?', 'multiple_choice', N'Yes, it is.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yes, it is.', 1), (@QuestionID, N'No, it is.', 0), (@QuestionID, N'Yes, I am.', 0), (@QuestionID, N'It is red.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ the door.', 'multiple_choice', N'Open');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Open', 1), (@QuestionID, N'Stand', 0), (@QuestionID, N'Sit', 0), (@QuestionID, N'Look', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ at the board.', 'multiple_choice', N'Look');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Look', 1), (@QuestionID, N'See', 0), (@QuestionID, N'Watch', 0), (@QuestionID, N'Listen', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What is this? (Desk)', 'multiple_choice', N'It is a desk.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'It is a desk.', 1), (@QuestionID, N'It is a chair.', 0), (@QuestionID, N'It is a board.', 0), (@QuestionID, N'It is a pen.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My bag is ______ (màu vàng).', 'multiple_choice', N'yellow');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'yellow', 1), (@QuestionID, N'red', 0), (@QuestionID, N'blue', 0), (@QuestionID, N'green', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is it a crayon? - No, it ______.', 'multiple_choice', N'is not');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'is not', 1), (@QuestionID, N'is', 0), (@QuestionID, N'are', 0), (@QuestionID, N'am', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my ______ (trường học).', 'multiple_choice', N'school');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'school', 1), (@QuestionID, N'class', 0), (@QuestionID, N'bag', 0), (@QuestionID, N'desk', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I have a ______ (thước kẻ).', 'multiple_choice', N'ruler');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'ruler', 1), (@QuestionID, N'rubber', 0), (@QuestionID, N'pencil', 0), (@QuestionID, N'pen', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Close the ______.', 'multiple_choice', N'window');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'window', 1), (@QuestionID, N'desk', 0), (@QuestionID, N'chair', 0), (@QuestionID, N'pencil', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What color is the pencil?', 'multiple_choice', N'It is blue.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'It is blue.', 1), (@QuestionID, N'It is a pen.', 0), (@QuestionID, N'Yes, it is.', 0), (@QuestionID, N'No, it is not.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is this a board?', 'multiple_choice', N'Yes, it is.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yes, it is.', 1), (@QuestionID, N'It is big.', 0), (@QuestionID, N'I like it.', 0), (@QuestionID, N'No, I don''t.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sit ______ the chair.', 'multiple_choice', N'on');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'on', 1), (@QuestionID, N'in', 0), (@QuestionID, N'at', 0), (@QuestionID, N'to', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is a ______ (bức tranh).', 'multiple_choice', N'picture');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'picture', 1), (@QuestionID, N'book', 0), (@QuestionID, N'board', 0), (@QuestionID, N'door', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I put my book in my ______.', 'multiple_choice', N'bag');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'bag', 1), (@QuestionID, N'desk', 0), (@QuestionID, N'chair', 0), (@QuestionID, N'pencil', 0);

-- FILL BLANK
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is ______ eraser.', 'fill_in_blank', N'an');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'an', 1), (@QuestionID, N'a', 0), (@QuestionID, N'two', 0), (@QuestionID, N'some', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my ______ (cặp sách).', 'fill_in_blank', N'bag');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'bag', 1), (@QuestionID, N'bat', 0), (@QuestionID, N'bad', 0), (@QuestionID, N'bug', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is it a book? - Yes, it ______.', 'fill_in_blank', N'is');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'is', 1), (@QuestionID, N'isn''t', 0), (@QuestionID, N'are', 0), (@QuestionID, N'not', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I write on a ______.', 'fill_in_blank', N'desk');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'desk', 1), (@QuestionID, N'chair', 0), (@QuestionID, N'bag', 0), (@QuestionID, N'floor', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ is it? - It is a pen.', 'fill_in_blank', N'What');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'What', 1), (@QuestionID, N'Who', 0), (@QuestionID, N'Where', 0), (@QuestionID, N'How', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is a ______ (bút chì).', 'fill_in_blank', N'pencil');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'pencil', 1), (@QuestionID, N'pen', 0), (@QuestionID, N'cil', 0), (@QuestionID, N'book', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ the door.', 'fill_in_blank', N'Open');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Open', 1), (@QuestionID, N'Sit', 0), (@QuestionID, N'Stand', 0), (@QuestionID, N'Look', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'______ the window.', 'fill_in_blank', N'Close');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Close', 1), (@QuestionID, N'Open', 0), (@QuestionID, N'Look', 0), (@QuestionID, N'See', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is a ______ (thước kẻ).', 'fill_in_blank', N'ruler');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'ruler', 1), (@QuestionID, N'rubber', 0), (@QuestionID, N'run', 0), (@QuestionID, N'rule', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is a ______ (cái ghế).', 'fill_in_blank', N'chair');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'chair', 1), (@QuestionID, N'hair', 0), (@QuestionID, N'air', 0), (@QuestionID, N'care', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Look at the ______ (bảng).', 'fill_in_blank', N'board');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'board', 1), (@QuestionID, N'boat', 0), (@QuestionID, N'boar', 0), (@QuestionID, N'book', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is it a pen? - No, it ______.', 'fill_in_blank', N'is not');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'is not', 1), (@QuestionID, N'is', 0), (@QuestionID, N'are', 0), (@QuestionID, N'am', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My bag is ______ (màu đỏ).', 'fill_in_blank', N'red');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'red', 1), (@QuestionID, N'read', 0), (@QuestionID, N'bed', 0), (@QuestionID, N'led', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I have a ______ (bút sáp).', 'fill_in_blank', N'crayon');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'crayon', 1), (@QuestionID, N'clay', 0), (@QuestionID, N'car', 0), (@QuestionID, N'cat', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'It is my ______ (sách).', 'fill_in_blank', N'book');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'book', 1), (@QuestionID, N'look', 0), (@QuestionID, N'cook', 0), (@QuestionID, N'hook', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sit on the ______.', 'fill_in_blank', N'chair');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'chair', 1), (@QuestionID, N'desk', 0), (@QuestionID, N'table', 0), (@QuestionID, N'floor', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'The pencil is ______ (màu vàng).', 'fill_in_blank', N'yellow');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'yellow', 1), (@QuestionID, N'blue', 0), (@QuestionID, N'red', 0), (@QuestionID, N'green', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is ______ eraser.', 'fill_in_blank', N'an');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'an', 1), (@QuestionID, N'a', 0), (@QuestionID, N'the', 0), (@QuestionID, N'one', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is this your ______ (hộp bút)?', 'fill_in_blank', N'pencil case');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'pencil case', 1), (@QuestionID, N'bag', 0), (@QuestionID, N'book', 0), (@QuestionID, N'pen', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I  to ______ (trường học).', 'fill_in_blank', N'school');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'school', 1), (@QuestionID, N'home', 0), (@QuestionID, N'zoo', 0), (@QuestionID, N'park', 0);



-- #################################################################
-- UNIT 2: MY FAMILY
-- #################################################################
PRINT N'--- Nạp Unit 2 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 2: My Family',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) 
VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Dad", "R": "Bố"}', 1),
(@QuestionID, N'{"L": "Mom", "R": "Mẹ"}', 1),
(@QuestionID, N'{"L": "Grandma", "R": "Bà"}', 1),
(@QuestionID, N'{"L": "Grandpa", "R": "Ông"}', 1),
(@QuestionID, N'{"L": "Brother", "R": "Anh/Em trai"}', 1),
(@QuestionID, N'{"L": "Sister", "R": "Chị/Em gái"}', 1),
(@QuestionID, N'{"L": "Baby", "R": "Em bé"}', 1),
(@QuestionID, N'{"L": "Uncle", "R": "Chú/Bác"}', 1),
(@QuestionID, N'{"L": "Aunt", "R": "Cô/Dì"}', 1),
(@QuestionID, N'{"L": "Cousin", "R": "Anh chị em họ"}', 1),
(@QuestionID, N'{"L": "Family", "R": "Gia đình"}', 1),
(@QuestionID, N'{"L": "Parents", "R": "Bố mẹ"}', 1),
(@QuestionID, N'{"L": "Grandparents", "R": "Ông bà"}', 1),
(@QuestionID, N'{"L": "Man", "R": "Người đàn ông"}', 1),
(@QuestionID, N'{"L": "Woman", "R": "Người phụ nữ"}', 1),
(@QuestionID, N'{"L": "Boy", "R": "Bé trai"}', 1),
(@QuestionID, N'{"L": "Girl", "R": "Bé gái"}', 1),
(@QuestionID, N'{"L": "Love", "R": "Yêu thương"}', 1),
(@QuestionID, N'{"L": "Photo", "R": "Bức ảnh"}', 1),
(@QuestionID, N'{"L": "Who", "R": "Ai"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) 
VALUES (@TopicID, N'Sắp xếp các từ thành câu hoàn chỉnh', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'This is my mom', 1),
(@QuestionID, N'Who is this', 1),
(@QuestionID, N'I love my family', 1),
(@QuestionID, N'Is this your dad', 1),
(@QuestionID, N'She is my sister', 1),
(@QuestionID, N'He is my brother', 1),
(@QuestionID, N'My grandma is kind', 1),
(@QuestionID, N'This is my baby brother', 1),
(@QuestionID, N'My grandpa is old', 1),
(@QuestionID, N'Do you have a sister', 1),
(@QuestionID, N'Yes I do', 1),
(@QuestionID, N'No I do not', 1),
(@QuestionID, N'That is my uncle', 1),
(@QuestionID, N'I have two brothers', 1),
(@QuestionID, N'She is a baby', 1),
(@QuestionID, N'My dad is tall', 1),
(@QuestionID, N'My mom is beautiful', 1),
(@QuestionID, N'This is my cousin', 1),
(@QuestionID, N'Who is he', 1),
(@QuestionID, N'Who is she', 1);

-- QUIZ
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Who is this?', 'multiple_choice', N'This is my dad.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'This is my dad.', 1), (@QuestionID, N'It is a pen.', 0), (@QuestionID, N'I am fine.', 0), (@QuestionID, N'Yes, it is.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is this your sister?', 'multiple_choice', N'Yes, it is.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yes, it is.', 1), (@QuestionID, N'Yes, I am.', 0), (@QuestionID, N'No, I don''t.', 0), (@QuestionID, N'She is happy.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My father''s father is my ______.', 'multiple_choice', N'grandpa');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'grandpa', 1), (@QuestionID, N'grandma', 0), (@QuestionID, N'dad', 0), (@QuestionID, N'uncle', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my ______ (em bé).', 'multiple_choice', N'baby');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'baby', 1), (@QuestionID, N'babies', 0), (@QuestionID, N'boy', 0), (@QuestionID, N'girl', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I love my ______.', 'multiple_choice', N'family');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'family', 1), (@QuestionID, N'pen', 0), (@QuestionID, N'bag', 0), (@QuestionID, N'desk', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my ______ (bà).', 'multiple_choice', N'grandma');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'grandma', 1), (@QuestionID, N'grandpa', 0), (@QuestionID, N'dad', 0), (@QuestionID, N'mom', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'He is my ______ (anh trai).', 'multiple_choice', N'brother');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'brother', 1), (@QuestionID, N'sister', 0), (@QuestionID, N'mom', 0), (@QuestionID, N'dad', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Who is he?', 'multiple_choice', N'He is my uncle.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'He is my uncle.', 1), (@QuestionID, N'She is my aunt.', 0), (@QuestionID, N'It is a dog.', 0), (@QuestionID, N'I am fine.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is that your mom?', 'multiple_choice', N'No, it is my aunt.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'No, it is my aunt.', 1), (@QuestionID, N'Yes, I am.', 0), (@QuestionID, N'No, I don''t.', 0), (@QuestionID, N'It is red.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My mom''s sister is my ______.', 'multiple_choice', N'aunt');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'aunt', 1), (@QuestionID, N'uncle', 0), (@QuestionID, N'grandma', 0), (@QuestionID, N'sister', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my ______ (chị họ).', 'multiple_choice', N'cousin');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'cousin', 1), (@QuestionID, N'brother', 0), (@QuestionID, N'dad', 0), (@QuestionID, N'grandpa', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I have a ______ (em gái).', 'multiple_choice', N'sister');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'sister', 1), (@QuestionID, N'brother', 0), (@QuestionID, N'baby', 0), (@QuestionID, N'dad', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is your dad tall?', 'multiple_choice', N'Yes, he is.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yes, he is.', 1), (@QuestionID, N'Yes, she is.', 0), (@QuestionID, N'No, she isn''t.', 0), (@QuestionID, N'Yes, it is.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is a picture of my ______.', 'multiple_choice', N'family');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'family', 1), (@QuestionID, N'class', 0), (@QuestionID, N'school', 0), (@QuestionID, N'bag', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Who is she?', 'multiple_choice', N'She is my grandma.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'She is my grandma.', 1), (@QuestionID, N'He is my dad.', 0), (@QuestionID, N'It is a cat.', 0), (@QuestionID, N'I am Kim.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Do you have a brother?', 'multiple_choice', N'Yes, I do.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'Yes, I do.', 1), (@QuestionID, N'Yes, I am.', 0), (@QuestionID, N'No, it isn''t.', 0), (@QuestionID, N'He is my brother.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My ______ (bố) is strong.', 'multiple_choice', N'dad');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'dad', 1), (@QuestionID, N'mom', 0), (@QuestionID, N'sister', 0), (@QuestionID, N'baby', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'She is my ______ (mẹ).', 'multiple_choice', N'mom');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'mom', 1), (@QuestionID, N'dad', 0), (@QuestionID, N'brother', 0), (@QuestionID, N'grandpa', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Who is the baby?', 'multiple_choice', N'It is my brother.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'It is my brother.', 1), (@QuestionID, N'It is a doll.', 0), (@QuestionID, N'It is a cat.', 0), (@QuestionID, N'He is tall.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My ______ (ông) is nice.', 'multiple_choice', N'grandpa');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'grandpa', 1), (@QuestionID, N'grandma', 0), (@QuestionID, N'aunt', 0), (@QuestionID, N'sister', 0);

-- FILL BLANK
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my ______ (mẹ).', 'fill_in_blank', N'mom');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'mom', 1), (@QuestionID, N'dad', 0), (@QuestionID, N'sis', 0), (@QuestionID, N'bro', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Who ______ this?', 'fill_in_blank', N'is');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'is', 1), (@QuestionID, N'are', 0), (@QuestionID, N'am', 0), (@QuestionID, N'be', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'He is my ______ (anh trai).', 'fill_in_blank', N'brother');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'brother', 1), (@QuestionID, N'sister', 0), (@QuestionID, N'mother', 0), (@QuestionID, N'father', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'She is my ______ (chị gái).', 'fill_in_blank', N'sister');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'sister', 1), (@QuestionID, N'brother', 0), (@QuestionID, N'dad', 0), (@QuestionID, N'mom', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My dad is ______ (cao).', 'fill_in_blank', N'tall');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'tall', 1), (@QuestionID, N'ball', 0), (@QuestionID, N'call', 0), (@QuestionID, N'mall', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I love my ______ (gia đình).', 'fill_in_blank', N'family');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'family', 1), (@QuestionID, N'class', 0), (@QuestionID, N'school', 0), (@QuestionID, N'home', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my ______ (bố).', 'fill_in_blank', N'dad');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'dad', 1), (@QuestionID, N'mom', 0), (@QuestionID, N'bad', 0), (@QuestionID, N'sad', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is this your ______ (bà)?', 'fill_in_blank', N'grandma');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'grandma', 1), (@QuestionID, N'grandpa', 0), (@QuestionID, N'dad', 0), (@QuestionID, N'mom', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Who is ______ (cô ấy)?', 'fill_in_blank', N'she');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'she', 1), (@QuestionID, N'he', 0), (@QuestionID, N'it', 0), (@QuestionID, N'they', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Who is ______ (anh ấy)?', 'fill_in_blank', N'he');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'he', 1), (@QuestionID, N'she', 0), (@QuestionID, N'it', 0), (@QuestionID, N'we', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is my baby ______ (em trai).', 'fill_in_blank', N'brother');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'brother', 1), (@QuestionID, N'sister', 0), (@QuestionID, N'mother', 0), (@QuestionID, N'father', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My ______ (ông) is old.', 'fill_in_blank', N'grandpa');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'grandpa', 1), (@QuestionID, N'grandma', 0), (@QuestionID, N'dad', 0), (@QuestionID, N'mom', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I have a ______ (cô/dì).', 'fill_in_blank', N'aunt');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'aunt', 1), (@QuestionID, N'uncle', 0), (@QuestionID, N'ant', 0), (@QuestionID, N'fan', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'He is my ______ (chú/bác).', 'fill_in_blank', N'uncle');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'uncle', 1), (@QuestionID, N'aunt', 0), (@QuestionID, N'dad', 0), (@QuestionID, N'mom', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Do you have a ______ (chị)?', 'fill_in_blank', N'sister');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'sister', 1), (@QuestionID, N'brother', 0), (@QuestionID, N'mother', 0), (@QuestionID, N'father', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'This is a ______ (bức ảnh).', 'fill_in_blank', N'photo');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'photo', 1), (@QuestionID, N'phone', 0), (@QuestionID, N'book', 0), (@QuestionID, N'bag', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is she your mom? - Yes, she ______.', 'fill_in_blank', N'is');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'is', 1), (@QuestionID, N'isn''t', 0), (@QuestionID, N'are', 0), (@QuestionID, N'am', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'My ______ (anh em họ) is funny.', 'fill_in_blank', N'cousin');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'cousin', 1), (@QuestionID, N'brother', 0), (@QuestionID, N'sister', 0), (@QuestionID, N'baby', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Is he your dad? - No, he ______.', 'fill_in_blank', N'isn''t');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'isn''t', 1), (@QuestionID, N'is', 0), (@QuestionID, N'not', 0), (@QuestionID, N'aren''t', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'I am a ______ (bé gái).', 'fill_in_blank', N'girl');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'girl', 1), (@QuestionID, N'boy', 0), (@QuestionID, N'baby', 0), (@QuestionID, N'kid', 0);


-- #################################################################
-- UNIT 3: MY BODY
-- #################################################################
PRINT N'--- Nạp Unit 3 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 3: My Body',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Head", "R": "Đầu"}', 1),
(@QuestionID, N'{"L": "Arm", "R": "Cánh tay"}', 1),
(@QuestionID, N'{"L": "Leg", "R": "Chân"}', 1),
(@QuestionID, N'{"L": "Hand", "R": "Bàn tay"}', 1),
(@QuestionID, N'{"L": "Foot", "R": "Bàn chân"}', 1),
(@QuestionID, N'{"L": "Feet", "R": "Hai bàn chân"}', 1),
(@QuestionID, N'{"L": "Finger", "R": "Ngón tay"}', 1),
(@QuestionID, N'{"L": "Toe", "R": "Ngón chân"}', 1),
(@QuestionID, N'{"L": "Body", "R": "Cơ thể"}', 1),
(@QuestionID, N'{"L": "Knee", "R": "Đầu gối"}', 1),
(@QuestionID, N'{"L": "Shoulder", "R": "Vai"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sắp xếp câu', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'Touch your head', 1),
(@QuestionID, N'Clap your hands', 1),
(@QuestionID, N'These are my arms', 1),
(@QuestionID, N'Stomp your feet', 1),
(@QuestionID, N'I have two hands', 1),
(@QuestionID, N'Shake your legs', 1),
(@QuestionID, N'Wave your arms', 1);

-- QUIZ & FILL BLANK (Mẫu)
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'What is this?', 'multiple_choice', N'It is my head.');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'It is my head.', 1), (@QuestionID, N'It is a book.', 0), (@QuestionID, N'They are arms.', 0), (@QuestionID, N'I am happy.', 0);

INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'These are my ______ (cánh tay).', 'fill_in_blank', N'arms');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES (@QuestionID, N'arms', 1), (@QuestionID, N'legs', 0), (@QuestionID, N'hands', 0), (@QuestionID, N'heads', 0);


-- #################################################################
-- UNIT 4: MY FACE
-- #################################################################
PRINT N'--- Nạp Unit 4 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 4: My Face',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Eye", "R": "Mắt"}', 1),
(@QuestionID, N'{"L": "Nose", "R": "Mũi"}', 1),
(@QuestionID, N'{"L": "Mouth", "R": "Miệng"}', 1),
(@QuestionID, N'{"L": "Ear", "R": "Tai"}', 1),
(@QuestionID, N'{"L": "Face", "R": "Khuôn mặt"}', 1),
(@QuestionID, N'{"L": "Hair", "R": "Tóc"}', 1),
(@QuestionID, N'{"L": "Teeth", "R": "Răng"}', 1),
(@QuestionID, N'{"L": "Cheek", "R": "Má"}', 1),
(@QuestionID, N'{"L": "Lips", "R": "Môi"}', 1),
(@QuestionID, N'{"L": "Chin", "R": "Cằm"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sắp xếp câu', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'This is my nose', 1),
(@QuestionID, N'Open your mouth', 1),
(@QuestionID, N'Touch your ears', 1),
(@QuestionID, N'I have two eyes', 1),
(@QuestionID, N'My hair is black', 1);


-- #################################################################
-- UNIT 5: ANIMALS
-- #################################################################
PRINT N'--- Nạp Unit 5 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 5: Animals',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Cat", "R": "Mèo"}', 1),
(@QuestionID, N'{"L": "Dog", "R": "Chó"}', 1),
(@QuestionID, N'{"L": "Duck", "R": "Vịt"}', 1),
(@QuestionID, N'{"L": "Bird", "R": "Chim"}', 1),
(@QuestionID, N'{"L": "Cow", "R": "Bò"}', 1),
(@QuestionID, N'{"L": "Pig", "R": "Lợn"}', 1),
(@QuestionID, N'{"L": "Chicken", "R": "Gà"}', 1),
(@QuestionID, N'{"L": "at", "R": "Dê"}', 1),
(@QuestionID, N'{"L": "Horse", "R": "Ngựa"}', 1),
(@QuestionID, N'{"L": "Sheep", "R": "Cừu"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sắp xếp câu', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'I see a cat', 1),
(@QuestionID, N'It is a dog', 1),
(@QuestionID, N'Do you like birds', 1),
(@QuestionID, N'The duck says quack', 1),
(@QuestionID, N'The cow eats grass', 1);


-- #################################################################
-- UNIT 6: MY HOUSE
-- #################################################################
PRINT N'--- Nạp Unit 6 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 6: My House',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "House", "R": "Ngôi nhà"}', 1),
(@QuestionID, N'{"L": "Kitchen", "R": "Nhà bếp"}', 1),
(@QuestionID, N'{"L": "Bedroom", "R": "Phòng ngủ"}', 1),
(@QuestionID, N'{"L": "Bathroom", "R": "Phòng tắm"}', 1),
(@QuestionID, N'{"L": "Living room", "R": "Phòng khách"}', 1),
(@QuestionID, N'{"L": "Garden", "R": "Vườn"}', 1),
(@QuestionID, N'{"L": "Window", "R": "Cửa sổ"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sắp xếp câu', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'Where is Mom', 1),
(@QuestionID, N'She is in the kitchen', 1),
(@QuestionID, N'This is my house', 1),
(@QuestionID, N'I am in the bedroom', 1),
(@QuestionID, N'Is dad in the garden', 1);


-- #################################################################
-- UNIT 7: CLOTHES
-- #################################################################
PRINT N'--- Nạp Unit 7 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 7: Clothes',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Shirt", "R": "Áo sơ mi"}', 1),
(@QuestionID, N'{"L": "T-shirt", "R": "Áo phông"}', 1),
(@QuestionID, N'{"L": "Pants", "R": "Quần dài"}', 1),
(@QuestionID, N'{"L": "Shorts", "R": "Quần đùi"}', 1),
(@QuestionID, N'{"L": "Dress", "R": "Váy"}', 1),
(@QuestionID, N'{"L": "Skirt", "R": "Chân váy"}', 1),
(@QuestionID, N'{"L": "Hat", "R": "Mũ"}', 1),
(@QuestionID, N'{"L": "Shoes", "R": "Giày"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sắp xếp câu', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'I am wearing a dress', 1),
(@QuestionID, N'This is my hat', 1),
(@QuestionID, N'Are these your shoes', 1),
(@QuestionID, N'I like this shirt', 1),
(@QuestionID, N'My shorts are blue', 1);


-- #################################################################
-- UNIT 8: TOYS
-- #################################################################
PRINT N'--- Nạp Unit 8 ---';
INSERT INTO Topics (TopicName,GradeID) VALUES (N'Lớp 2 (CD) - Unit 8: Toys',2);
SET @TopicID = SCOPE_IDENTITY();

-- MATCHING
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Nối từ vựng', 'matching', N'Pairs');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'{"L": "Teddy bear", "R": "Gấu bông"}', 1),
(@QuestionID, N'{"L": "Car", "R": "Ô tô"}', 1),
(@QuestionID, N'{"L": "Robot", "R": "Người máy"}', 1),
(@QuestionID, N'{"L": "Ball", "R": "Bóng"}', 1),
(@QuestionID, N'{"L": "Kite", "R": "Diều"}', 1),
(@QuestionID, N'{"L": "Bike", "R": "Xe đạp"}', 1),
(@QuestionID, N'{"L": "Train", "R": "Tàu hỏa"}', 1),
(@QuestionID, N'{"L": "Plane", "R": "Máy bay"}', 1);

-- SCRAMBLE
INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer) VALUES (@TopicID, N'Sắp xếp câu', 'scramble', N'Sentences');
SET @QuestionID = SCOPE_IDENTITY();
INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
(@QuestionID, N'I have a robot', 1),
(@QuestionID, N'Do you like cars', 1),
(@QuestionID, N'It is a blue kite', 1),
(@QuestionID, N'My teddy bear is soft', 1),
(@QuestionID, N'Let us play ball', 1);
PRINT N'✅ ĐÃ HOÀN TẤT NẠP DỮ LIỆU (FULL UNIT 0-8) THEO ĐÚNG CẤU TRÚC YÊU CẦU!';

USE GameHocTiengAnh1;
GO

PRINT N'=== NẠP DỮ LIỆU REVIEW LỚP 3 (FULL UNIT 0-8) ===';

-- ==========================================================
-- BƯỚC 1: TẠO TOPICS CHO LỚP 3 (VỚI GRADE ID = 3)
-- ==========================================================
-- Lưu ý: Giả định GradeID của Lớp 3 là 3. Nếu khác, hãy sửa số 3 bên dưới.

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 0: Getting Started')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 0: Getting Started', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 1: My Classroom')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 1: My Classroom', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 2: My World')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 2: My World', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 3: My Family')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 3: My Family', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 4: My House')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 4: My House', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 5: Cool Clothes')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 5: Cool Clothes', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 6: My Toys')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 6: My Toys', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 7: My Body')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 7: My Body', 3);

IF NOT EXISTS (SELECT 1 FROM Topics WHERE TopicName = N'Lớp 3 - Unit 8: Good Food')
    INSERT INTO Topics (TopicName, GradeID) VALUES (N'Lớp 3 - Unit 8: Good Food', 3);

-- ==========================================================
-- BƯỚC 2: KHAI BÁO BIẾN ID (ĐỂ DÙNG CHUNG CHO CẢ SCRIPT)
-- ==========================================================
DECLARE @Unit0ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 0: Getting Started');
DECLARE @Unit1ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 1: My Classroom');
DECLARE @Unit2ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 2: My World');
DECLARE @Unit3ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 3: My Family');
DECLARE @Unit4ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 4: My House');
DECLARE @Unit5ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 5: Cool Clothes');
DECLARE @Unit6ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 6: My Toys');
DECLARE @Unit7ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 7: My Body');
DECLARE @Unit8ID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName = N'Lớp 3 - Unit 8: Good Food');

-- ==========================================================
-- BƯỚC 3: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 0)
-- ==========================================================
PRINT N'--- Processing Unit 0 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('listen',    N'lắng nghe',     'Verb',   N'Listen, please.', @Unit0ID),
('read',      N'đọc',           'Verb',   N'Read the sentence.', @Unit0ID),
('point',     N'chỉ (tay)',     'Verb',   N'Point to the picture.', @Unit0ID),
('say',       N'nói',           'Verb',   N'Say your name.', @Unit0ID),
('write',     N'viết',          'Verb',   N'Write “Mia”.', @Unit0ID),
('draw',      N'vẽ',            'Verb',   N'Draw a sun.', @Unit0ID),
('sing',      N'hát',           'Verb',   N'Sing a song.', @Unit0ID),
('count',     N'đếm',           'Verb',   N'Count from one to ten.', @Unit0ID),
('stand up',  N'đứng lên',      'Phrase', N'Stand up, please.', @Unit0ID),
('sit down',  N'ngồi xuống',    'Phrase', N'Sit down, please.', @Unit0ID),
('hi',                N'xin chào (thân mật)', 'Interjection', N'Hi, Nam!', @Unit0ID),
('hello',             N'xin chào',            'Interjection', N'Hello!', @Unit0ID),
('goodbye',           N'tạm biệt',            'Interjection', N'Goodbye! See you.', @Unit0ID),
('bye',               N'tạm biệt',            'Interjection', N'Bye!', @Unit0ID),
('nice to meet you',  N'rất vui được gặp bạn','Phrase',       N'Nice to meet you.', @Unit0ID),
('how are you',       N'bạn khỏe không',      'Phrase',       N'How are you?', @Unit0ID),
('i am fine',         N'mình khỏe',           'Phrase',       N'I am fine, thanks.', @Unit0ID),
('thanks',            N'cảm ơn',              'Interjection', N'Thanks!', @Unit0ID),
('red',    N'màu đỏ',        'Adjective', N'It is red.', @Unit0ID),
('purple', N'màu tím',       'Adjective', N'It is purple.', @Unit0ID),
('yellow', N'màu vàng',      'Adjective', N'It is yellow.', @Unit0ID),
('blue',   N'màu xanh dương','Adjective', N'It is blue.', @Unit0ID),
('orange', N'màu cam',       'Adjective', N'It is orange.', @Unit0ID),
('white',  N'màu trắng',     'Adjective', N'It is white.', @Unit0ID),
('black',  N'màu đen',       'Adjective', N'It is black.', @Unit0ID),
('green',  N'màu xanh lá',   'Adjective', N'It is green.', @Unit0ID),
('brown',  N'màu nâu',       'Adjective', N'It is brown.', @Unit0ID),
('pink',   N'màu hồng',      'Adjective', N'It is pink.', @Unit0ID),
('one',   N'số 1',  'Number', N'One, two, three...', @Unit0ID),
('two',   N'số 2',  'Number', N'Two pencils.', @Unit0ID),
('three', N'số 3',  'Number', N'Three books.', @Unit0ID),
('four',  N'số 4',  'Number', N'Four pens.', @Unit0ID),
('five',  N'số 5',  'Number', N'Five chairs.', @Unit0ID),
('six',   N'số 6',  'Number', N'Six pictures.', @Unit0ID),
('seven', N'số 7',  'Number', N'Seven rulers.', @Unit0ID),
('eight', N'số 8',  'Number', N'Eight erasers.', @Unit0ID),
('nine',  N'số 9',  'Number', N'Nine crayons.', @Unit0ID),
('ten',   N'số 10', 'Number', N'Ten students.', @Unit0ID),
('eleven',N'số 11', 'Number', N'Eleven.', @Unit0ID),
('twelve',N'số 12', 'Number', N'Twelve.', @Unit0ID),
('thirteen',N'số 13','Number',N'Thirteen.', @Unit0ID),
('fourteen',N'số 14','Number',N'Fourteen.', @Unit0ID),
('fifteen',N'số 15','Number',N'Fifteen.', @Unit0ID),
('sixteen',N'số 16','Number',N'Sixteen.', @Unit0ID),
('seventeen',N'số 17','Number',N'Seventeen.', @Unit0ID),
('eighteen',N'số 18','Number',N'Eighteen.', @Unit0ID),
('nineteen',N'số 19','Number',N'Nineteen.', @Unit0ID),
('twenty', N'số 20','Number', N'Twenty.', @Unit0ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'Chào hỏi & giới thiệu', N'Hi/Hello. I''m + Name. / My name''s + Name.', N'Dùng để chào và nói tên.', N'Hello. I''m Mia. / My name''s Nam.', @Unit0ID),
(N'Hỏi tên', N'What''s your name?', N'Hỏi tên người khác.', N'What''s your name? My name''s Lan.', @Unit0ID),
(N'Hỏi thăm sức khỏe', N'How are you? — I''m fine/good, thanks.', N'Hỏi và trả lời “khỏe không”.', N'How are you? I''m fine, thanks.', @Unit0ID),
(N'Đánh vần tên', N'How do you spell your name? — (A-B-C...)', N'Hỏi cách đánh vần tên.', N'How do you spell your name? M-I-A.', @Unit0ID),
(N'Hỏi tuổi', N'How old are you? — I''m + number.', N'Hỏi và trả lời tuổi.', N'How old are you? I''m eight.', @Unit0ID),
(N'Hỏi màu', N'What color is it? — It''s + color.', N'Hỏi và trả lời màu sắc.', N'What color is it? It''s red.', @Unit0ID),
(N'Mệnh lệnh lịch sự', N'Stand up/Sit down, please.', N'Dùng trong lớp học.', N'Stand up, please.', @Unit0ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 4: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 1)
-- ==========================================================
PRINT N'--- Processing Unit 1 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('backpack', N'ba lô', 'Noun', N'My backpack is blue.', @Unit1ID),
('board', N'bảng', 'Noun', N'The board is big.', @Unit1ID),
('book', N'sách', 'Noun', N'This is my book.', @Unit1ID),
('chair', N'ghế', 'Noun', N'Sit on the chair.', @Unit1ID),
('clock', N'đồng hồ', 'Noun', N'The clock is on the wall.', @Unit1ID),
('computer', N'máy tính', 'Noun', N'I use a computer.', @Unit1ID),
('crayon', N'bút sáp màu', 'Noun', N'I have a crayon.', @Unit1ID),
('desk', N'bàn học', 'Noun', N'This desk is new.', @Unit1ID),
('eraser', N'cục tẩy', 'Noun', N'I need an eraser.', @Unit1ID),
('glue', N'keo dán', 'Noun', N'Use glue for the paper.', @Unit1ID),
('map', N'bản đồ', 'Noun', N'The map is here.', @Unit1ID),
('paper', N'giấy', 'Noun', N'I have paper.', @Unit1ID),
('pen', N'bút mực', 'Noun', N'This pen is black.', @Unit1ID),
('pencil', N'bút chì', 'Noun', N'This is a pencil.', @Unit1ID),
('picture', N'bức tranh', 'Noun', N'That picture is nice.', @Unit1ID),
('ruler', N'thước kẻ', 'Noun', N'This ruler is long.', @Unit1ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'Sở hữu: I have...', N'I have a/an + noun.', N'Nói mình có đồ vật.', N'I have a crayon.', @Unit1ID),
(N'Hỏi vật: What is it?', N'What is it? — It''s a/an + noun.', N'Hỏi và trả lời “đây là gì”.', N'What is it? It''s a pencil.', @Unit1ID),
(N'Hỏi số lượng', N'How many + plural noun(s)? — One/Two/Three...', N'Hỏi và trả lời số lượng đồ vật.', N'How many pencils? Three.', @Unit1ID),
(N'There is / There are', N'There is a + singular noun. / There are + number + plural noun(s).', N'Nói có cái gì ở đâu đó.', N'There is a book. There are two pens.', @Unit1ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 5: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 2)
-- ==========================================================
PRINT N'--- Processing Unit 2 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('bird', N'con chim', 'Noun', N'A bird can fly.', @Unit2ID),
('bush', N'bụi cây', 'Noun', N'The frog is near the bush.', @Unit2ID),
('butterfly', N'con bướm', 'Noun', N'It is a butterfly.', @Unit2ID),
('cloud', N'đám mây', 'Noun', N'The clouds are in the sky.', @Unit2ID),
('flower', N'bông hoa', 'Noun', N'A flower is beautiful.', @Unit2ID),
('moon', N'mặt trăng', 'Noun', N'The moon is bright.', @Unit2ID),
('mountain', N'ngọn núi', 'Noun', N'That mountain is high.', @Unit2ID),
('ocean', N'đại dương', 'Noun', N'The ocean is big.', @Unit2ID),
('pet dog', N'chó nuôi', 'Noun', N'This is my pet dog.', @Unit2ID),
('rainbow', N'cầu vồng', 'Noun', N'I see a rainbow.', @Unit2ID),
('river', N'sông', 'Noun', N'The river is long.', @Unit2ID),
('rock', N'hòn đá', 'Noun', N'It is on the rock.', @Unit2ID),
('sky', N'bầu trời', 'Noun', N'The sky is blue.', @Unit2ID),
('star', N'ngôi sao', 'Noun', N'I see a star.', @Unit2ID),
('sun', N'mặt trời', 'Noun', N'The sun is hot.', @Unit2ID),
('tree', N'cây', 'Noun', N'It is a tree.', @Unit2ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'Yes/No: Is it a/an...?', N'Is it a/an + noun? — Yes, it is. / No, it isn''t.', N'Hỏi đoán 1 vật/con vật.', N'Is it a butterfly? Yes, it is.', @Unit2ID),
(N'What is it?', N'What is it? — It''s a/an + noun.', N'Hỏi và trả lời “đây là gì”.', N'What is it? It''s a tree.', @Unit2ID),
(N'What are they?', N'What are they? — They''re + plural noun(s).', N'Hỏi & trả lời nhiều vật.', N'What are they? They''re rocks.', @Unit2ID),
(N'Where is/are...?', N'Where is the + noun? — It''s in/on/near + place. / Where are the + plural noun(s)? — They''re in/on + place.', N'Hỏi & trả lời vị trí.', N'Where are the clouds? They''re in the sky.', @Unit2ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 6: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 3)
-- ==========================================================
PRINT N'--- Processing Unit 3 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('beautiful', N'đẹp', 'Adjective', N'She is beautiful.', @Unit3ID),
('big', N'lớn', 'Adjective', N'My family is big.', @Unit3ID),
('brother', N'anh/em trai', 'Noun', N'I have one brother.', @Unit3ID),
('father', N'bố', 'Noun', N'This is my father.', @Unit3ID),
('grandfather', N'ông', 'Noun', N'He is my grandfather.', @Unit3ID),
('grandmother', N'bà', 'Noun', N'She is my grandmother.', @Unit3ID),
('grandparents',N'ông bà', 'Noun', N'I love my grandparents.', @Unit3ID),
('handsome', N'đẹp trai', 'Adjective', N'He is handsome.', @Unit3ID),
('mother', N'mẹ', 'Noun', N'This is my mother.', @Unit3ID),
('old', N'già', 'Adjective', N'He is old.', @Unit3ID),
('parents', N'bố mẹ', 'Noun', N'My parents are kind.', @Unit3ID),
('short', N'thấp/lùn', 'Adjective', N'She is short.', @Unit3ID),
('sister', N'chị/em gái', 'Noun', N'She is my sister.', @Unit3ID),
('small', N'nhỏ', 'Adjective', N'The baby is small.', @Unit3ID),
('tall', N'cao', 'Adjective', N'He is tall.', @Unit3ID),
('young', N'trẻ', 'Adjective', N'She is young.', @Unit3ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'Hỏi người này là ai', N'Who''s this? — (He/She is) my + family member. / It''s my + family member.', N'Hỏi và trả lời về người trong gia đình.', N'Who''s this? She''s my sister.', @Unit3ID),
(N'Hỏi: Who''s he / she?', N'Who''s he? — He''s my + family member. / Who''s she? — She''s my + family member.', N'Hỏi và trả lời “ông ấy/bà ấy/cô ấy là ai”.', N'Who''s he? He''s my grandfather.', @Unit3ID),
(N'Hỏi số lượng anh/em', N'How many brothers/sisters do you have? — I have + number + brothers/sisters. / I have no brothers/sisters.', N'Hỏi và trả lời số lượng anh/em.', N'How many brothers do you have? I have two brothers. / I have no brothers.', @Unit3ID),
(N'Miêu tả bằng tính từ', N'The + person + is + adjective.', N'Nói đặc điểm (cao/thấp/già/trẻ...).', N'The sister is tall.', @Unit3ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 7: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 4)
-- ==========================================================
PRINT N'--- Processing Unit 4 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('bathroom', N'phòng tắm', 'Noun', N'The bathroom is clean.', @Unit4ID),
('bed', N'cái giường', 'Noun', N'This is my bed.', @Unit4ID),
('bedroom', N'phòng ngủ', 'Noun', N'My bedroom is small.', @Unit4ID),
('cleaning', N'dọn dẹp', 'Verb', N'I am cleaning.', @Unit4ID),
('cooking', N'nấu ăn', 'Verb', N'Mom is cooking.', @Unit4ID),
('dining room', N'phòng ăn', 'Noun', N'The dining room is big.', @Unit4ID),
('eating', N'ăn', 'Verb', N'I am eating.', @Unit4ID),
('kitchen', N'nhà bếp', 'Noun', N'The kitchen is here.', @Unit4ID),
('lamp', N'đèn', 'Noun', N'The lamp is on the table.', @Unit4ID),
('living room', N'phòng khách', 'Noun', N'We are in the living room.', @Unit4ID),
('playing', N'chơi', 'Verb', N'They are playing.', @Unit4ID),
('sleeping', N'ngủ', 'Verb', N'He is sleeping.', @Unit4ID),
('sofa', N'ghế sofa', 'Noun', N'The sofa is brown.', @Unit4ID),
('table', N'cái bàn', 'Noun', N'The table is big.', @Unit4ID),
('taking a bath', N'tắm bồn', 'Phrase', N'She is taking a bath.', @Unit4ID),
('toilet', N'bồn cầu/nhà vệ sinh','Noun', N'The toilet is in the bathroom.', @Unit4ID),
('washing dishes',N'rửa bát', 'Phrase', N'He is washing dishes.', @Unit4ID),
('watching TV', N'xem TV', 'Phrase', N'She is watching TV.', @Unit4ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'There is / There isn''t (số ít)', N'Is there a/an + noun + in the + place? — Yes, there is. / No, there isn''t.', N'Hỏi và trả lời có 1 vật không (số ít).', N'Is there a flower in the dining room? Yes, there is.', @Unit4ID),
(N'There are / There aren''t (số nhiều)', N'Are there any + plural noun(s) + in the + place? — Yes, there are. / No, there aren''t.', N'Hỏi và trả lời có nhiều vật không (số nhiều).', N'Are there any chairs in the kitchen? No, there aren''t.', @Unit4ID),
(N'Hỏi vị trí', N'Where are you? — I''m at home. / I''m in the + place.', N'Hỏi và trả lời bạn đang ở đâu.', N'Where are you? I''m at home.', @Unit4ID),
(N'Hiện tại tiếp diễn: hỏi đang làm gì', N'What are you doing? — I''m + V-ing.', N'Hỏi và trả lời hành động đang diễn ra.', N'What are you doing? I''m cleaning.', @Unit4ID),
(N'Hiện tại tiếp diễn: he/she', N'What is he/she doing? — He''s/She''s + V-ing.', N'Hỏi và trả lời hành động của người khác.', N'What is she doing? She''s watching TV.', @Unit4ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 8: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 5)
-- ==========================================================
PRINT N'--- Processing Unit 5 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('boots', N'ủng/giày bốt', 'Noun', N'These are my boots.', @Unit5ID),
('brown', N'màu nâu', 'Adjective', N'It is brown.', @Unit5ID),
('closet', N'tủ quần áo', 'Noun', N'The closet is big.', @Unit5ID),
('dress', N'váy (liền)', 'Noun', N'She wears a dress.', @Unit5ID),
('gloves', N'găng tay', 'Noun', N'I wear gloves.', @Unit5ID),
('hanger', N'móc treo', 'Noun', N'Put it on a hanger.', @Unit5ID),
('hat', N'mũ', 'Noun', N'This is my hat.', @Unit5ID),
('jacket', N'áo khoác', 'Noun', N'I have a jacket.', @Unit5ID),
('pants', N'quần dài', 'Noun', N'He wears pants.', @Unit5ID),
('pink', N'màu hồng', 'Adjective', N'It is pink.', @Unit5ID),
('scarf', N'khăn quàng', 'Noun', N'This is my scarf.', @Unit5ID),
('shelf', N'kệ', 'Noun', N'It is on the shelf.', @Unit5ID),
('shirt', N'áo sơ mi', 'Noun', N'This is my shirt.', @Unit5ID),
('shoes', N'giày', 'Noun', N'I wear shoes.', @Unit5ID),
('skirt', N'váy', 'Noun', N'She wears a skirt.', @Unit5ID),
('socks', N'tất/vớ', 'Noun', N'I wear socks.', @Unit5ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'Hỏi đang mặc gì', N'What are you wearing? — I''m wearing + (color) + clothes.', N'Hỏi và trả lời đang mặc gì.', N'What are you wearing? I''m wearing yellow shoes.', @Unit5ID),
(N'Yes/No: Are you wearing...?', N'Are you wearing + (color) + clothes? — Yes, I am. / No, I''m not.', N'Hỏi xác nhận có đang mặc món đó không.', N'Are you wearing green gloves? Yes, I am.', @Unit5ID),
(N'This/That (số ít) + my', N'This is my + noun. / That is my + noun.', N'Chỉ đồ vật số ít (gần/xa).', N'This is my blue scarf. That is my brown hat.', @Unit5ID),
(N'These/Those (số nhiều) + my', N'These are my + plural noun(s). / Those are my + plural noun(s).', N'Chỉ đồ vật số nhiều (gần/xa).', N'These are my purple boots. Those are my green gloves.', @Unit5ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 9: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 6)
-- ==========================================================
PRINT N'--- Processing Unit 6 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('ball', N'quả bóng', 'Noun', N'I want a ball.', @Unit6ID),
('bike', N'xe đạp', 'Noun', N'This is my bike.', @Unit6ID),
('car', N'ô tô (đồ chơi)', 'Noun', N'I have a toy car.', @Unit6ID),
('doll', N'búp bê', 'Noun', N'This is a doll.', @Unit6ID),
('drum', N'trống', 'Noun', N'I play the drum.', @Unit6ID),
('game', N'trò chơi', 'Noun', N'Let''s play a game.', @Unit6ID),
('kite', N'cái diều', 'Noun', N'I want a kite.', @Unit6ID),
('plane', N'máy bay (đồ chơi)','Noun', N'This is a plane.', @Unit6ID),
('puppet', N'con rối', 'Noun', N'I have a puppet.', @Unit6ID),
('puzzle', N'trò xếp hình', 'Noun', N'This puzzle is fun.', @Unit6ID),
('robot', N'rô-bốt', 'Noun', N'This is a robot.', @Unit6ID),
('teddy bear',N'gấu bông', 'Noun', N'I love my teddy bear.', @Unit6ID),
('top', N'con quay', 'Noun', N'This top is new.', @Unit6ID),
('train', N'tàu hỏa (đồ chơi)','Noun', N'I have a train.', @Unit6ID),
('truck', N'xe tải (đồ chơi)','Noun', N'I have a truck.', @Unit6ID),
('yo-yo', N'yo-yo', 'Noun', N'This is my yo-yo.', @Unit6ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'What do you want?', N'What do you want? — I want a/an + noun.', N'Hỏi và trả lời muốn gì.', N'What do you want? I want a ball.', @Unit6ID),
(N'Yes/No: Do you want...?', N'Do you want a/an + noun? — Yes, I do. / No, I don''t.', N'Hỏi có muốn món đó không.', N'Do you want a kite? Yes, I do.', @Unit6ID),
(N'Is this your...?', N'Is this your + noun? — Yes, it is. / No, it isn''t.', N'Hỏi xác nhận đồ vật số ít.', N'Is this your robot? Yes, it is.', @Unit6ID),
(N'Are these your...?', N'Are these your + plural noun(s)? — Yes, they are. / No, they aren''t.', N'Hỏi xác nhận đồ vật số nhiều.', N'Are these your balls? No, they aren''t.', @Unit6ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 10: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 7)
-- ==========================================================
PRINT N'--- Processing Unit 7 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('arm', N'cánh tay', 'Noun', N'This is my arm.', @Unit7ID),
('curly hair', N'tóc xoăn', 'Phrase', N'She has curly hair.', @Unit7ID),
('ear', N'tai', 'Noun', N'This is my ear.', @Unit7ID),
('eye', N'mắt', 'Noun', N'My eyes are brown.', @Unit7ID),
('fly', N'bay', 'Verb', N'A bird can fly.', @Unit7ID),
('foot', N'bàn chân', 'Noun', N'This is my foot.', @Unit7ID),
('hair', N'tóc', 'Noun', N'Her hair is long.', @Unit7ID),
('hand', N'bàn tay', 'Noun', N'These are my hands.', @Unit7ID),
('head', N'đầu', 'Noun', N'This is my head.', @Unit7ID),
('jump', N'nhảy', 'Verb', N'I can jump.', @Unit7ID),
('leg', N'cẳng chân', 'Noun', N'This is my leg.', @Unit7ID),
('mouth', N'miệng', 'Noun', N'This is my mouth.', @Unit7ID),
('nose', N'mũi', 'Noun', N'This is my nose.', @Unit7ID),
('round eyes', N'đôi mắt tròn', 'Phrase', N'She has round eyes.', @Unit7ID),
('run', N'chạy', 'Verb', N'I can run.', @Unit7ID),
('straight hair',N'tóc thẳng', 'Phrase', N'He has straight hair.', @Unit7ID),
('strong arms', N'cánh tay khỏe', 'Phrase', N'He has strong arms.', @Unit7ID),
('walk', N'đi bộ', 'Verb', N'I can walk.', @Unit7ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'These/Those (tay)', N'These are my + plural noun(s). / Those are your + plural noun(s).', N'Chỉ bộ phận cơ thể số nhiều (gần/xa).', N'These are my hands. Those are your hands.', @Unit7ID),
(N'Our/His/Her/Their', N'Our/His/Her/Their + noun + is/are + adjective.', N'Dùng tính từ sở hữu + miêu tả.', N'Our hands are small. His eyes are brown.', @Unit7ID),
(N'Can / Can''t', N'Can you + verb? — Yes, I can. / No, I can''t. / I can + verb.', N'Hỏi và nói về khả năng.', N'Can you run? Yes, I can. I can run.', @Unit7ID),
(N'Has (miêu tả)', N'She/He has + adjective + noun.', N'Miêu tả đặc điểm (tóc, mắt...).', N'She has round eyes.', @Unit7ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

-- ==========================================================
-- BƯỚC 11: NẠP TỪ VỰNG & NGỮ PHÁP (UNIT 8)
-- ==========================================================
PRINT N'--- Processing Unit 8 ---';
INSERT INTO Vocabulary (Word, Meaning, WordType, Example, TopicID)
SELECT * FROM (VALUES
('apple', N'táo', 'Noun', N'I like apples.', @Unit8ID),
('banana', N'chuối', 'Noun', N'I like bananas.', @Unit8ID),
('chicken', N'gà', 'Noun', N'I like chicken.', @Unit8ID),
('coconut water', N'nước dừa', 'Phrase', N'I drink coconut water.', @Unit8ID),
('cookie', N'bánh quy', 'Noun', N'I like cookies.', @Unit8ID),
('egg', N'trứng', 'Noun', N'There are some eggs.', @Unit8ID),
('fish', N'cá', 'Noun', N'I like fish.', @Unit8ID),
('lemonade', N'nước chanh', 'Noun', N'I drink lemonade.', @Unit8ID),
('milk', N'sữa', 'Noun', N'There is a lot of milk.', @Unit8ID),
('milkshake', N'sữa lắc', 'Noun', N'I like milkshake.', @Unit8ID),
('orange juice', N'nước cam', 'Phrase', N'I drink orange juice.', @Unit8ID),
('rice', N'cơm/gạo', 'Noun', N'I eat rice.', @Unit8ID),
('sandwich', N'bánh mì kẹp', 'Noun', N'I eat a sandwich.', @Unit8ID),
('soda', N'nước ngọt', 'Noun', N'I don''t drink soda.', @Unit8ID),
('soup', N'súp/canh', 'Noun', N'I like soup.', @Unit8ID),
('tea', N'trà', 'Noun', N'I drink tea.', @Unit8ID),
('vegetables', N'rau', 'Noun', N'I eat vegetables.', @Unit8ID),
('water', N'nước', 'Noun', N'There is some water.', @Unit8ID)
) AS v(Word,Meaning,WordType,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Vocabulary x WHERE x.TopicID=v.TopicID AND x.Word=v.Word);

INSERT INTO Grammar (GrammarName, Structure, Usage, Example, TopicID)
SELECT * FROM (VALUES
(N'Hỏi món yêu thích', N'What''s your favorite food? — (Food). / I like + food.', N'Hỏi và trả lời món ăn yêu thích.', N'What''s your favorite food? Apples. I like apples.', @Unit8ID),
(N'Do you like...?', N'Do you like + food? — Yes, I do. I like + food. / No, I don''t. I don''t like + food.', N'Hỏi và trả lời thích/không thích.', N'Do you like bananas? Yes, I do. I like bananas. / No, I don''t. I don''t like bananas.', @Unit8ID),
(N'There is (a/an/some)', N'There is a/an + singular noun. / There is some + uncountable noun.', N'Nói có 1 vật (đếm được) hoặc 1 ít (không đếm được).', N'There is an apple. There is some water.', @Unit8ID),
(N'There are (some/many/a lot of)', N'There are some + plural noun(s). / There are many/a lot of + plural noun(s).', N'Nói có nhiều vật (đếm được).', N'There are some eggs. There are many cookies. There are a lot of bananas.', @Unit8ID),
(N'A lot of (uncountable)', N'There is a lot of + uncountable noun.', N'Nói nhiều với danh từ không đếm được.', N'There is a lot of milk.', @Unit8ID)
) AS g(GrammarName,Structure,Usage,Example,TopicID)
WHERE NOT EXISTS (SELECT 1 FROM Grammar x WHERE x.TopicID=g.TopicID AND x.GrammarName=g.GrammarName);

PRINT N'✅ ĐÃ NẠP XONG DỮ LIỆU REVIEW LỚP 3!';




USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO DỮ LIỆU ROUND 1 (MATCHING) CHO LỚP 3 ===';

-- KHAI BÁO BIẾN ID (TÌM THEO TÊN CHUẨN "Lớp 3 - ...")

DECLARE @Q_ID INT;
DECLARE @U0 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 0%');
DECLARE @U1 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 1%');
DECLARE @U2 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 2%');
DECLARE @U3 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 3%');
DECLARE @U4 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 4%');
DECLARE @U5 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 5%');
DECLARE @U6 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 6%');
DECLARE @U7 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 7%');
DECLARE @U8 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 8%');

-- Kiểm tra xem có tìm thấy Topic không
IF @U0 IS NULL PRINT N'⚠️ CẢNH BÁO: Không tìm thấy Topic Lớp 3! Hãy kiểm tra lại tên trong bảng Topics.';

-- ==========================================================
-- UNIT 0 (LỚP 3)
-- ==========================================================
IF @U0 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U0, N'Nối từ và câu Unit 0 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Hello", "R": "Xin chào"}', 1),
    (@Q_ID, N'{"L": "Goodbye", "R": "Tạm biệt"}', 1),
    (@Q_ID, N'{"L": "Please", "R": "Làm ơn"}', 1),
    (@Q_ID, N'{"L": "Thank you", "R": "Cảm ơn"}', 1),
    (@Q_ID, N'{"L": "Sorry", "R": "Xin lỗi"}', 1),
    (@Q_ID, N'{"L": "Yes", "R": "Vâng / Có"}', 1),
    (@Q_ID, N'{"L": "No", "R": "Không"}', 1),
    (@Q_ID, N'{"L": "One", "R": "Số 1"}', 1),
    (@Q_ID, N'{"L": "Two", "R": "Số 2"}', 1),
    (@Q_ID, N'{"L": "Red", "R": "Màu đỏ"}', 1),
    (@Q_ID, N'{"L": "Blue", "R": "Màu xanh dương"}', 1),
    (@Q_ID, N'{"L": "Green", "R": "Màu xanh lá"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "What is your name?", "R": "My name is Lan."}', 1),
    (@Q_ID, N'{"L": "How are you?", "R": "I am fine, thanks."}', 1),
    (@Q_ID, N'{"L": "Nice to meet you.", "R": "Nice to meet you, too."}', 1),
    (@Q_ID, N'{"L": "How old are you?", "R": "I am eight years old."}', 1),
    (@Q_ID, N'{"L": "How do you spell your name?", "R": "L-A-N."}', 1),
    (@Q_ID, N'{"L": "What color is it?", "R": "It is red."}', 1),
    (@Q_ID, N'{"L": "Stand up, please.", "R": "OK."}', 1),
    (@Q_ID, N'{"L": "Sit down, please.", "R": "OK."}', 1);
END

-- ==========================================================
-- UNIT 1 (LỚP 3)
-- ==========================================================
IF @U1 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U1, N'Nối từ và câu Unit 1 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Book", "R": "Quyển sách"}', 1),
    (@Q_ID, N'{"L": "Pen", "R": "Bút mực"}', 1),
    (@Q_ID, N'{"L": "Pencil", "R": "Bút chì"}', 1),
    (@Q_ID, N'{"L": "Ruler", "R": "Cây thước"}', 1),
    (@Q_ID, N'{"L": "Eraser", "R": "Cục tẩy"}', 1),
    (@Q_ID, N'{"L": "Backpack", "R": "Cặp sách"}', 1),
    (@Q_ID, N'{"L": "Desk", "R": "Bàn học"}', 1),
    (@Q_ID, N'{"L": "Chair", "R": "Cái ghế"}', 1),
    (@Q_ID, N'{"L": "Board", "R": "Bảng"}', 1),
    (@Q_ID, N'{"L": "Window", "R": "Cửa sổ"}', 1),
    (@Q_ID, N'{"L": "Door", "R": "Cửa ra vào"}', 1),
    (@Q_ID, N'{"L": "Teacher", "R": "Giáo viên"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "What is this?", "R": "It is a book."}', 1),
    (@Q_ID, N'{"L": "What are these?", "R": "They are pencils."}', 1),
    (@Q_ID, N'{"L": "How many pens are there?", "R": "There are three pens."}', 1),
    (@Q_ID, N'{"L": "Open your book, please.", "R": "OK."}', 1),
    (@Q_ID, N'{"L": "Close your book, please.", "R": "OK."}', 1),
    (@Q_ID, N'{"L": "Where is the book?", "R": "It is on the desk."}', 1),
    (@Q_ID, N'{"L": "Is this your backpack?", "R": "Yes, it is."}', 1),
    (@Q_ID, N'{"L": "Is that your ruler?", "R": "No, it is not."}', 1);
END

-- ==========================================================
-- UNIT 2 (LỚP 3)
-- ==========================================================
IF @U2 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U2, N'Nối từ và câu Unit 2 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Sun", "R": "Mặt trời"}', 1),
    (@Q_ID, N'{"L": "Moon", "R": "Mặt trăng"}', 1),
    (@Q_ID, N'{"L": "Sky", "R": "Bầu trời"}', 1),
    (@Q_ID, N'{"L": "Cloud", "R": "Đám mây"}', 1),
    (@Q_ID, N'{"L": "Tree", "R": "Cây"}', 1),
    (@Q_ID, N'{"L": "Flower", "R": "Bông hoa"}', 1),
    (@Q_ID, N'{"L": "Bird", "R": "Con chim"}', 1),
    (@Q_ID, N'{"L": "Fish", "R": "Con cá"}', 1),
    (@Q_ID, N'{"L": "Frog", "R": "Con ếch"}', 1),
    (@Q_ID, N'{"L": "River", "R": "Con sông"}', 1),
    (@Q_ID, N'{"L": "Mountain", "R": "Ngọn núi"}', 1),
    (@Q_ID, N'{"L": "Rainbow", "R": "Cầu vồng"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "What is it?", "R": "It is a bird."}', 1),
    (@Q_ID, N'{"L": "Is it a frog?", "R": "Yes, it is."}', 1),
    (@Q_ID, N'{"L": "Is it a fish?", "R": "No, it is not."}', 1),
    (@Q_ID, N'{"L": "What are they?", "R": "They are clouds."}', 1),
    (@Q_ID, N'{"L": "Where is the bird?", "R": "It is in the tree."}', 1),
    (@Q_ID, N'{"L": "Where is the fish?", "R": "It is in the river."}', 1),
    (@Q_ID, N'{"L": "The sky is", "R": "blue."}', 1),
    (@Q_ID, N'{"L": "I can see", "R": "a rainbow."}', 1);
END

-- ==========================================================
-- UNIT 3 (LỚP 3)
-- ==========================================================
IF @U3 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U3, N'Nối từ và câu Unit 3 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Father", "R": "Bố"}', 1),
    (@Q_ID, N'{"L": "Mother", "R": "Mẹ"}', 1),
    (@Q_ID, N'{"L": "Brother", "R": "Anh/Em trai"}', 1),
    (@Q_ID, N'{"L": "Sister", "R": "Chị/Em gái"}', 1),
    (@Q_ID, N'{"L": "Grandfather", "R": "Ông"}', 1),
    (@Q_ID, N'{"L": "Grandmother", "R": "Bà"}', 1),
    (@Q_ID, N'{"L": "Parents", "R": "Bố mẹ"}', 1),
    (@Q_ID, N'{"L": "Grandparents", "R": "Ông bà"}', 1),
    (@Q_ID, N'{"L": "Tall", "R": "Cao"}', 1),
    (@Q_ID, N'{"L": "Short", "R": "Thấp/Lùn"}', 1),
    (@Q_ID, N'{"L": "Young", "R": "Trẻ"}', 1),
    (@Q_ID, N'{"L": "Old", "R": "Già"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "Who''s this?", "R": "She is my mother."}', 1),
    (@Q_ID, N'{"L": "Who''s he?", "R": "He is my father."}', 1),
    (@Q_ID, N'{"L": "Who''s she?", "R": "She is my sister."}', 1),
    (@Q_ID, N'{"L": "How many brothers do you have?", "R": "I have two brothers."}', 1),
    (@Q_ID, N'{"L": "How many sisters do you have?", "R": "I have one sister."}', 1),
    (@Q_ID, N'{"L": "The grandfather is", "R": "old."}', 1),
    (@Q_ID, N'{"L": "The brother is", "R": "tall."}', 1),
    (@Q_ID, N'{"L": "My family is", "R": "big."}', 1);
END

-- ==========================================================
-- UNIT 4 (LỚP 3)
-- ==========================================================
IF @U4 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U4, N'Nối từ và câu Unit 4 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Bedroom", "R": "Phòng ngủ"}', 1),
    (@Q_ID, N'{"L": "Bathroom", "R": "Phòng tắm"}', 1),
    (@Q_ID, N'{"L": "Kitchen", "R": "Nhà bếp"}', 1),
    (@Q_ID, N'{"L": "Living room", "R": "Phòng khách"}', 1),
    (@Q_ID, N'{"L": "Dining room", "R": "Phòng ăn"}', 1),
    (@Q_ID, N'{"L": "Bed", "R": "Cái giường"}', 1),
    (@Q_ID, N'{"L": "Sofa", "R": "Ghế sofa"}', 1),
    (@Q_ID, N'{"L": "Table", "R": "Cái bàn"}', 1),
    (@Q_ID, N'{"L": "Lamp", "R": "Đèn"}', 1),
    (@Q_ID, N'{"L": "Toilet", "R": "Nhà vệ sinh/Bồn cầu"}', 1),
    (@Q_ID, N'{"L": "Watch TV", "R": "Xem TV"}', 1),
    (@Q_ID, N'{"L": "Wash dishes", "R": "Rửa bát"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "Is there a lamp in the bedroom?", "R": "Yes, there is."}', 1),
    (@Q_ID, N'{"L": "Are there any chairs in the kitchen?", "R": "No, there aren''t."}', 1),
    (@Q_ID, N'{"L": "Where are you?", "R": "I am at home."}', 1),
    (@Q_ID, N'{"L": "Where are you?", "R": "I am in the living room."}', 1),
    (@Q_ID, N'{"L": "What are you doing?", "R": "I am cooking."}', 1),
    (@Q_ID, N'{"L": "What are you doing?", "R": "I am cleaning."}', 1),
    (@Q_ID, N'{"L": "What is she doing?", "R": "She is watching TV."}', 1),
    (@Q_ID, N'{"L": "What is he doing?", "R": "He is washing dishes."}', 1);
END

-- ==========================================================
-- UNIT 5 (LỚP 3)
-- ==========================================================
IF @U5 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U5, N'Nối từ và câu Unit 5 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Hat", "R": "Mũ"}', 1),
    (@Q_ID, N'{"L": "Scarf", "R": "Khăn quàng"}', 1),
    (@Q_ID, N'{"L": "Jacket", "R": "Áo khoác"}', 1),
    (@Q_ID, N'{"L": "Shirt", "R": "Áo sơ mi"}', 1),
    (@Q_ID, N'{"L": "Dress", "R": "Váy liền"}', 1),
    (@Q_ID, N'{"L": "Skirt", "R": "Váy"}', 1),
    (@Q_ID, N'{"L": "Pants", "R": "Quần dài"}', 1),
    (@Q_ID, N'{"L": "Socks", "R": "Tất/Vớ"}', 1),
    (@Q_ID, N'{"L": "Shoes", "R": "Giày"}', 1),
    (@Q_ID, N'{"L": "Boots", "R": "Giày bốt/Ủng"}', 1),
    (@Q_ID, N'{"L": "Gloves", "R": "Găng tay"}', 1),
    (@Q_ID, N'{"L": "Closet", "R": "Tủ quần áo"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "What are you wearing?", "R": "I am wearing a jacket."}', 1),
    (@Q_ID, N'{"L": "What are you wearing?", "R": "I am wearing shoes."}', 1),
    (@Q_ID, N'{"L": "Are you wearing a hat?", "R": "Yes, I am."}', 1),
    (@Q_ID, N'{"L": "Are you wearing gloves?", "R": "No, I am not."}', 1),
    (@Q_ID, N'{"L": "This is my", "R": "scarf."}', 1),
    (@Q_ID, N'{"L": "That is my", "R": "hat."}', 1),
    (@Q_ID, N'{"L": "These are my", "R": "boots."}', 1),
    (@Q_ID, N'{"L": "Those are my", "R": "socks."}', 1);
END

-- ==========================================================
-- UNIT 6 (LỚP 3)
-- ==========================================================
IF @U6 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U6, N'Nối từ và câu Unit 6 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Ball", "R": "Quả bóng"}', 1),
    (@Q_ID, N'{"L": "Doll", "R": "Búp bê"}', 1),
    (@Q_ID, N'{"L": "Robot", "R": "Rô-bốt"}', 1),
    (@Q_ID, N'{"L": "Teddy bear", "R": "Gấu bông"}', 1),
    (@Q_ID, N'{"L": "Kite", "R": "Cái diều"}', 1),
    (@Q_ID, N'{"L": "Puzzle", "R": "Trò xếp hình"}', 1),
    (@Q_ID, N'{"L": "Car", "R": "Ô tô đồ chơi"}', 1),
    (@Q_ID, N'{"L": "Train", "R": "Tàu hỏa đồ chơi"}', 1),
    (@Q_ID, N'{"L": "Truck", "R": "Xe tải đồ chơi"}', 1),
    (@Q_ID, N'{"L": "Drum", "R": "Trống"}', 1),
    (@Q_ID, N'{"L": "Bike", "R": "Xe đạp"}', 1),
    (@Q_ID, N'{"L": "Yo-yo", "R": "Yo-yo"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "What do you want?", "R": "I want a ball."}', 1),
    (@Q_ID, N'{"L": "What do you want?", "R": "I want a kite."}', 1),
    (@Q_ID, N'{"L": "Do you want a robot?", "R": "Yes, I do."}', 1),
    (@Q_ID, N'{"L": "Do you want a doll?", "R": "No, I don''t."}', 1),
    (@Q_ID, N'{"L": "Is this your teddy bear?", "R": "Yes, it is."}', 1),
    (@Q_ID, N'{"L": "Is this your car?", "R": "No, it isn''t."}', 1),
    (@Q_ID, N'{"L": "Are these your balls?", "R": "Yes, they are."}', 1),
    (@Q_ID, N'{"L": "Are these your trains?", "R": "No, they aren''t."}', 1);
END

-- ==========================================================
-- UNIT 7 (LỚP 3)
-- ==========================================================
IF @U7 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U7, N'Nối từ và câu Unit 7 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Head", "R": "Đầu"}', 1),
    (@Q_ID, N'{"L": "Hair", "R": "Tóc"}', 1),
    (@Q_ID, N'{"L": "Eye", "R": "Mắt"}', 1),
    (@Q_ID, N'{"L": "Ear", "R": "Tai"}', 1),
    (@Q_ID, N'{"L": "Nose", "R": "Mũi"}', 1),
    (@Q_ID, N'{"L": "Mouth", "R": "Miệng"}', 1),
    (@Q_ID, N'{"L": "Hand", "R": "Bàn tay"}', 1),
    (@Q_ID, N'{"L": "Arm", "R": "Cánh tay"}', 1),
    (@Q_ID, N'{"L": "Leg", "R": "Chân"}', 1),
    (@Q_ID, N'{"L": "Foot", "R": "Bàn chân"}', 1),
    (@Q_ID, N'{"L": "Run", "R": "Chạy"}', 1),
    (@Q_ID, N'{"L": "Jump", "R": "Nhảy"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "These are my", "R": "hands."}', 1),
    (@Q_ID, N'{"L": "Those are your", "R": "hands."}', 1),
    (@Q_ID, N'{"L": "He has", "R": "curly hair."}', 1),
    (@Q_ID, N'{"L": "She has", "R": "straight hair."}', 1),
    (@Q_ID, N'{"L": "Can you run?", "R": "Yes, I can."}', 1),
    (@Q_ID, N'{"L": "Can you jump?", "R": "No, I can''t."}', 1),
    (@Q_ID, N'{"L": "Our hands are", "R": "small."}', 1),
    (@Q_ID, N'{"L": "His eyes are", "R": "brown."}', 1);
END

-- ==========================================================
-- UNIT 8 (LỚP 3)
-- ==========================================================
IF @U8 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U8, N'Nối từ và câu Unit 8 (Lớp 3)', 'matching', N'Pairs');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'{"L": "Apple", "R": "Táo"}', 1),
    (@Q_ID, N'{"L": "Banana", "R": "Chuối"}', 1),
    (@Q_ID, N'{"L": "Chicken", "R": "Gà"}', 1),
    (@Q_ID, N'{"L": "Fish", "R": "Cá"}', 1),
    (@Q_ID, N'{"L": "Rice", "R": "Cơm/Gạo"}', 1),
    (@Q_ID, N'{"L": "Soup", "R": "Súp/Canh"}', 1),
    (@Q_ID, N'{"L": "Sandwich", "R": "Bánh mì kẹp"}', 1),
    (@Q_ID, N'{"L": "Milk", "R": "Sữa"}', 1),
    (@Q_ID, N'{"L": "Water", "R": "Nước"}', 1),
    (@Q_ID, N'{"L": "Orange juice", "R": "Nước cam"}', 1),
    (@Q_ID, N'{"L": "Cookies", "R": "Bánh quy"}', 1),
    (@Q_ID, N'{"L": "Eggs", "R": "Trứng"}', 1),
    -- GRAMMAR
    (@Q_ID, N'{"L": "What''s your favorite food?", "R": "I like apples."}', 1),
    (@Q_ID, N'{"L": "Do you like bananas?", "R": "Yes, I do."}', 1),
    (@Q_ID, N'{"L": "Do you like fish?", "R": "No, I don''t."}', 1),
    (@Q_ID, N'{"L": "There is an", "R": "apple."}', 1),
    (@Q_ID, N'{"L": "There is some", "R": "water."}', 1),
    (@Q_ID, N'{"L": "There are some", "R": "eggs."}', 1),
    (@Q_ID, N'{"L": "There are many", "R": "cookies."}', 1),
    (@Q_ID, N'{"L": "There is a lot of", "R": "milk."}', 1);
END

PRINT N'✅ ĐÃ TẠO XONG ROUND 1 (MATCHING) CHO LỚP 3 (Dữ liệu Lớp 2 vẫn còn nguyên)!';
GO


USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO DỮ LIỆU ROUND 2 (SCRAMBLE) CHO LỚP 3 ===';

-- KHAI BÁO BIẾN ID (TÌM THEO TÊN CHUẨN "Lớp 3 - ...")

DECLARE @Q_ID INT;
DECLARE @U0 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 0%');
DECLARE @U1 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 1%');
DECLARE @U2 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 2%');
DECLARE @U3 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 3%');
DECLARE @U4 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 4%');
DECLARE @U5 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 5%');
DECLARE @U6 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 6%');
DECLARE @U7 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 7%');
DECLARE @U8 INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE N'Lớp 3 - Unit 8%');

-- Kiểm tra xem có tìm thấy Topic không
IF @U0 IS NULL PRINT N'⚠️ CẢNH BÁO: Không tìm thấy Topic Lớp 3! Hãy kiểm tra lại tên trong bảng Topics.';

-- ==========================================================
-- UNIT 0 (LỚP 3)
-- ==========================================================
IF @U0 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U0, N'Sắp xếp câu Unit 0 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'Hello my name is Nam', 1),
    (@Q_ID, N'What is your name', 1),
    (@Q_ID, N'My name is Lan', 1),
    (@Q_ID, N'How are you today', 1),
    (@Q_ID, N'I am fine thank you', 1),
    (@Q_ID, N'Nice to meet you', 1),
    (@Q_ID, N'Nice to meet you too', 1),
    (@Q_ID, N'How old are you', 1),
    (@Q_ID, N'I am eight years old', 1),
    (@Q_ID, N'How do you spell your name', 1),
    (@Q_ID, N'I spell it N A M', 1),
    (@Q_ID, N'What color is it', 1),
    (@Q_ID, N'It is red', 1),
    (@Q_ID, N'It is blue', 1),
    (@Q_ID, N'It is green', 1),
    (@Q_ID, N'Please stand up', 1),
    (@Q_ID, N'Please sit down', 1),
    (@Q_ID, N'Thank you very much', 1),
    (@Q_ID, N'Sorry I am late', 1),
    (@Q_ID, N'Goodbye see you later', 1);
END

-- ==========================================================
-- UNIT 1 (LỚP 3)
-- ==========================================================
IF @U1 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U1, N'Sắp xếp câu Unit 1 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What is this', 1),
    (@Q_ID, N'It is a book', 1),
    (@Q_ID, N'What are these', 1),
    (@Q_ID, N'They are pencils', 1),
    (@Q_ID, N'How many pens are there', 1),
    (@Q_ID, N'There are three pens', 1),
    (@Q_ID, N'Open your book please', 1),
    (@Q_ID, N'Close your book please', 1),
    (@Q_ID, N'Where is the book', 1),
    (@Q_ID, N'It is on the desk', 1),
    (@Q_ID, N'Is this your backpack', 1),
    (@Q_ID, N'Yes it is', 1),
    (@Q_ID, N'Is that your ruler', 1),
    (@Q_ID, N'No it is not', 1),
    (@Q_ID, N'Give me your pencil please', 1),
    (@Q_ID, N'Here you are', 1),
    (@Q_ID, N'This is my eraser', 1),
    (@Q_ID, N'That is my chair', 1),
    (@Q_ID, N'The teacher is in the classroom', 1),
    (@Q_ID, N'The window is open', 1);
END

-- ==========================================================
-- UNIT 2 (LỚP 3)
-- ==========================================================
IF @U2 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U2, N'Sắp xếp câu Unit 2 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What is it', 1),
    (@Q_ID, N'It is a bird', 1),
    (@Q_ID, N'Is it a frog', 1),
    (@Q_ID, N'Yes it is', 1),
    (@Q_ID, N'Is it a fish', 1),
    (@Q_ID, N'No it is not', 1),
    (@Q_ID, N'What are they', 1),
    (@Q_ID, N'They are clouds', 1),
    (@Q_ID, N'Where is the bird', 1),
    (@Q_ID, N'It is in the tree', 1),
    (@Q_ID, N'Where is the fish', 1),
    (@Q_ID, N'It is in the river', 1),
    (@Q_ID, N'The sky is blue', 1),
    (@Q_ID, N'I can see the sun', 1),
    (@Q_ID, N'I can see the moon', 1),
    (@Q_ID, N'There is a rainbow', 1),
    (@Q_ID, N'The flowers are beautiful', 1),
    (@Q_ID, N'The tree is tall', 1),
    (@Q_ID, N'The birds can fly', 1),
    (@Q_ID, N'The fish can swim', 1);
END

-- ==========================================================
-- UNIT 3 (LỚP 3)
-- ==========================================================
IF @U3 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U3, N'Sắp xếp câu Unit 3 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'Who is this', 1),
    (@Q_ID, N'She is my mother', 1),
    (@Q_ID, N'Who is he', 1),
    (@Q_ID, N'He is my father', 1),
    (@Q_ID, N'Who is she', 1),
    (@Q_ID, N'She is my sister', 1),
    (@Q_ID, N'Who is he', 1),
    (@Q_ID, N'He is my brother', 1),
    (@Q_ID, N'How many brothers do you have', 1),
    (@Q_ID, N'I have two brothers', 1),
    (@Q_ID, N'How many sisters do you have', 1),
    (@Q_ID, N'I have one sister', 1),
    (@Q_ID, N'My grandfather is old', 1),
    (@Q_ID, N'My grandmother is kind', 1),
    (@Q_ID, N'My brother is tall', 1),
    (@Q_ID, N'My sister is young', 1),
    (@Q_ID, N'This is my family', 1),
    (@Q_ID, N'My family is big', 1),
    (@Q_ID, N'I love my parents', 1),
    (@Q_ID, N'We are happy together', 1);
END

-- ==========================================================
-- UNIT 4 (LỚP 3)
-- ==========================================================
IF @U4 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U4, N'Sắp xếp câu Unit 4 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'Where are you', 1),
    (@Q_ID, N'I am at home', 1),
    (@Q_ID, N'Where are you', 1),
    (@Q_ID, N'I am in the living room', 1),
    (@Q_ID, N'Is there a lamp in the bedroom', 1),
    (@Q_ID, N'Yes there is', 1),
    (@Q_ID, N'Are there any chairs in the kitchen', 1),
    (@Q_ID, N'No there are not', 1),
    (@Q_ID, N'What are you doing', 1),
    (@Q_ID, N'I am cooking', 1),
    (@Q_ID, N'What are you doing', 1),
    (@Q_ID, N'I am cleaning', 1),
    (@Q_ID, N'What is he doing', 1),
    (@Q_ID, N'He is washing dishes', 1),
    (@Q_ID, N'What is she doing', 1),
    (@Q_ID, N'She is watching TV', 1),
    (@Q_ID, N'The kitchen is small', 1),
    (@Q_ID, N'The bedroom is big', 1),
    (@Q_ID, N'This is my house', 1),
    (@Q_ID, N'I love my home', 1);
END

-- ==========================================================
-- UNIT 5 (LỚP 3)
-- ==========================================================
IF @U5 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U5, N'Sắp xếp câu Unit 5 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What are you wearing', 1),
    (@Q_ID, N'I am wearing a jacket', 1),
    (@Q_ID, N'I am wearing shoes', 1),
    (@Q_ID, N'Are you wearing a hat', 1),
    (@Q_ID, N'Yes I am', 1),
    (@Q_ID, N'Are you wearing gloves', 1),
    (@Q_ID, N'No I am not', 1),
    (@Q_ID, N'This is my scarf', 1),
    (@Q_ID, N'That is my hat', 1),
    (@Q_ID, N'These are my boots', 1),
    (@Q_ID, N'Those are my socks', 1),
    (@Q_ID, N'I have a new dress', 1),
    (@Q_ID, N'He has a blue shirt', 1),
    (@Q_ID, N'She has a red skirt', 1),
    (@Q_ID, N'I put my clothes in the closet', 1),
    (@Q_ID, N'The jacket is warm', 1),
    (@Q_ID, N'The shoes are black', 1),
    (@Q_ID, N'The hat is nice', 1),
    (@Q_ID, N'I like my clothes', 1),
    (@Q_ID, N'Let us go outside', 1);
END

-- ==========================================================
-- UNIT 6 (LỚP 3)
-- ==========================================================
IF @U6 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U6, N'Sắp xếp câu Unit 6 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What do you want', 1),
    (@Q_ID, N'I want a ball', 1),
    (@Q_ID, N'I want a kite', 1),
    (@Q_ID, N'Do you want a robot', 1),
    (@Q_ID, N'Yes I do', 1),
    (@Q_ID, N'Do you want a doll', 1),
    (@Q_ID, N'No I do not', 1),
    (@Q_ID, N'Is this your teddy bear', 1),
    (@Q_ID, N'Yes it is', 1),
    (@Q_ID, N'Is this your car', 1),
    (@Q_ID, N'No it is not', 1),
    (@Q_ID, N'Are these your balls', 1),
    (@Q_ID, N'Yes they are', 1),
    (@Q_ID, N'Are these your trains', 1),
    (@Q_ID, N'No they are not', 1),
    (@Q_ID, N'I have a new puzzle', 1),
    (@Q_ID, N'The robot is cool', 1),
    (@Q_ID, N'The doll is pretty', 1),
    (@Q_ID, N'I like my toys', 1),
    (@Q_ID, N'Let us play together', 1);
END

-- ==========================================================
-- UNIT 7 (LỚP 3)
-- ==========================================================
IF @U7 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U7, N'Sắp xếp câu Unit 7 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'This is my head', 1),
    (@Q_ID, N'These are my hands', 1),
    (@Q_ID, N'Those are your hands', 1),
    (@Q_ID, N'He has curly hair', 1),
    (@Q_ID, N'She has straight hair', 1),
    (@Q_ID, N'His eyes are brown', 1),
    (@Q_ID, N'Her eyes are black', 1),
    (@Q_ID, N'Can you run', 1),
    (@Q_ID, N'Yes I can', 1),
    (@Q_ID, N'Can you jump', 1),
    (@Q_ID, N'No I cannot', 1),
    (@Q_ID, N'I can walk', 1),
    (@Q_ID, N'I can swim', 1),
    (@Q_ID, N'Wash your hands', 1),
    (@Q_ID, N'Brush your teeth', 1),
    (@Q_ID, N'Touch your nose', 1),
    (@Q_ID, N'Clap your hands', 1),
    (@Q_ID, N'Stamp your feet', 1),
    (@Q_ID, N'My body is strong', 1),
    (@Q_ID, N'We should exercise every day', 1);
END

-- ==========================================================
-- UNIT 8 (LỚP 3)
-- ==========================================================
IF @U8 IS NOT NULL
BEGIN
    INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
    VALUES (@U8, N'Sắp xếp câu Unit 8 (Lớp 3)', 'scramble', N'Sentences');
    SET @Q_ID = SCOPE_IDENTITY();

    INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
    (@Q_ID, N'What is your favorite food', 1),
    (@Q_ID, N'I like apples', 1),
    (@Q_ID, N'Do you like bananas', 1),
    (@Q_ID, N'Yes I do', 1),
    (@Q_ID, N'Do you like fish', 1),
    (@Q_ID, N'No I do not', 1),
    (@Q_ID, N'I want some water', 1),
    (@Q_ID, N'I drink milk every day', 1),
    (@Q_ID, N'I eat rice for lunch', 1),
    (@Q_ID, N'There is an apple on the table', 1),
    (@Q_ID, N'There are some eggs', 1),
    (@Q_ID, N'There are many cookies', 1),
    (@Q_ID, N'There is a lot of milk', 1),
    (@Q_ID, N'There is some soup', 1),
    (@Q_ID, N'I like orange juice', 1),
    (@Q_ID, N'He likes chicken', 1),
    (@Q_ID, N'She likes fish', 1),
    (@Q_ID, N'Let us eat together', 1),
    (@Q_ID, N'Do not eat too many cookies', 1),
    (@Q_ID, N'Food is good for our health', 1);
END

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU SẮP XẾP (ROUND 2) CHO LỚP 3!';
GO

USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO DỮ LIỆU ROUND 3 (TRẮC NGHIỆM) - LỚP 3 ===';

IF OBJECT_ID('tempdb..#AddQuiz') IS NOT NULL DROP PROCEDURE #AddQuiz;
GO

CREATE PROCEDURE #AddQuiz
    @UnitName NVARCHAR(100), -- VD: 'Lớp 3 - Unit 0'
    @QuestionText NVARCHAR(MAX),
    @CorrectAns NVARCHAR(255),
    @Wrong1 NVARCHAR(255),
    @Wrong2 NVARCHAR(255),
    @Wrong3 NVARCHAR(255)
AS
BEGIN
    -- Tìm đúng tên Topic bắt đầu bằng @UnitName
    DECLARE @TopicID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE @UnitName + N'%');
    DECLARE @QID INT;

    IF @TopicID IS NOT NULL
    BEGIN
        INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
        VALUES (@TopicID, @QuestionText, 'multiple_choice', @CorrectAns);

        SET @QID = SCOPE_IDENTITY();

        INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES
        (@QID, @CorrectAns, 1),
        (@QID, @Wrong1, 0),
        (@QID, @Wrong2, 0),
        (@QID, @Wrong3, 0);
    END
    ELSE
    BEGIN
        PRINT N'⚠️ Lỗi: Không tìm thấy Topic tên là: ' + @UnitName;
    END
END;
GO

-- ======================================================================================
-- 3. BẮT ĐẦU NẠP DỮ LIỆU (SỬ DỤNG TÊN CHUẨN: 'Lớp 3 - Unit...')
-- ======================================================================================

PRINT N'--- Đang nạp Unit 0: Greetings & Basic Classroom ---';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct greeting.', N'Hello!', N'Good night!', N'Goodbye!', N'Sorry!';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'What is your name?', N'My name is Nam.', N'I am fine.', N'I am eight.', N'It is a book.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'How are you?', N'I am fine, thank you.', N'My name is Lan.', N'Yes, I do.', N'It is red.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'How old are you?', N'I am eight years old.', N'I am Nam.', N'I like apples.', N'It is on the desk.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Nice to meet you.', N'Nice to meet you, too.', N'Good morning!', N'Yes, please.', N'No, thanks.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct farewell.', N'Goodbye. See you later.', N'Hello! How are you?', N'I am fine.', N'My name is Minh.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'How do you spell NAM?', N'N - A - M', N'N - O - M', N'M - A - N', N'A - N - M';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'What color is it? (Red)', N'It is red.', N'It is a pen.', N'I am nine.', N'Yes, I am.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the polite word.', N'Please', N'Blue', N'Chair', N'Water';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the polite answer to "Thank you".', N'You are welcome.', N'How are you?', N'Goodbye!', N'My name is Hoa.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'In class, the teacher says: "____ down."', N'Sit', N'Sing', N'Swim', N'Fly';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'In class, the teacher says: "____ up."', N'Stand', N'Open', N'Close', N'Look';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct question form.', N'What is your name?', N'What your name is?', N'What is name your?', N'Your name what is?';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct answer: "How are you?"', N'I am OK.', N'It is a ruler.', N'In the kitchen.', N'Nine books.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct sentence.', N'I am seven years old.', N'I seven years old am.', N'Old years seven I am.', N'I am old seven years.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Sorry, I am late. (Teacher says)', N'It is OK.', N'Good night!', N'Yes, please.', N'No, it is not.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct color word.', N'green', N'window', N'books', N'watch';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct response: "Good morning!"', N'Good morning!', N'Goodbye!', N'I am ten.', N'It is blue.';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct question: ask age.', N'How old are you?', N'How are you?', N'What is this?', N'Where are you?';
EXEC #AddQuiz N'Lớp 3 - Unit 0', N'Choose the correct answer: "What color is it?"', N'It is blue.', N'It is a desk.', N'It is my mother.', N'I am fine.';


PRINT N'--- Đang nạp Unit 1: My Classroom ---';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'What is this?', N'It is a book.', N'It is red.', N'I am eight.', N'In the kitchen.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'What are these?', N'They are pencils.', N'It is a pencil.', N'This is a pencil.', N'It is on the desk.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct plural form.', N'pencils', N'pencil', N'penciling', N'penciled';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Where is the book?', N'It is on the desk.', N'It is a desk.', N'It is blue.', N'Yes, it is.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'How many pens are there? (3)', N'There are three pens.', N'There is three pens.', N'They are three pen.', N'There are pen three.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct command: open.', N'Open your book, please.', N'Close your book, please.', N'Sit down, please.', N'Stand up, please.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct command: close.', N'Close your book, please.', N'Open your book, please.', N'Listen to music.', N'Go to the park.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Is this your ruler?', N'Yes, it is.', N'Yes, I do.', N'No, I am not.', N'They are rulers.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Is that your backpack?', N'No, it is not.', N'No, I do not.', N'Yes, I am.', N'Yes, they are.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct word: "____ you are."', N'Here', N'Where', N'What', N'When';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'This is my _____. (rubber)', N'eraser', N'river', N'brother', N'flower';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'That is my _____. (chair)', N'chair', N'cheer', N'chest', N'cheap';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct question for many things.', N'What are these?', N'What is this?', N'How old are you?', N'Where are you?';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct word: "on" (It is ____ the desk.)', N'on', N'in', N'under', N'with';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'The teacher is in the _____.', N'classroom', N'bathroom', N'bedroom', N'kitchen';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct sentence.', N'This is a pen.', N'This are a pen.', N'These is a pen.', N'They is a pen.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct sentence.', N'These are books.', N'This are books.', N'These is books.', N'This is books.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Where is the pencil?', N'It is under the chair.', N'It is a chair.', N'It is green.', N'Yes, it is.';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'Choose the correct word: "a ____ of paper"', N'piece', N'bottle', N'loaf', N'can';
EXEC #AddQuiz N'Lớp 3 - Unit 1', N'The window is _____.', N'open', N'old', N'orange', N'only';


PRINT N'--- Đang nạp Unit 2: Nature & Animals ---';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'What is it? (a bird)', N'It is a bird.', N'It is a fish.', N'It is a frog.', N'It is a cat.';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Where is the bird?', N'It is in the tree.', N'It is on the desk.', N'It is in the bag.', N'It is under the bed.';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Where is the fish?', N'It is in the river.', N'It is in the sky.', N'It is in the tree.', N'It is on the roof.';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct sentence.', N'The sky is blue.', N'The sky are blue.', N'The sky is book.', N'The sky blue is.';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct word: "clouds" are in the _____.', N'sky', N'river', N'kitchen', N'chair';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'I can see the ____ at night.', N'moon', N'sun', N'flower', N'chair';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'I can see the ____ in the morning.', N'sun', N'moon', N'stars', N'rainbow';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Birds can _____.', N'fly', N'swim', N'cook', N'drive';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Fish can _____.', N'swim', N'fly', N'jump', N'sing';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Frogs can _____.', N'jump', N'fly', N'draw', N'read';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct question.', N'Is it a frog?', N'Are it a frog?', N'Is a frog it?', N'It is a frog?';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct short answer: "Is it a fish?" (Yes)', N'Yes, it is.', N'Yes, I do.', N'Yes, they are.', N'Yes, I am.';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct short answer: "Is it a fish?" (No)', N'No, it is not.', N'No, I do not.', N'No, they are not.', N'No, I am not.';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'The flowers are _____.', N'beautiful', N'busy', N'boring', N'bitter';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'The tree is _____.', N'tall', N'taste', N'toy', N'today';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct word: "in" (The bird is ____ the tree.)', N'in', N'on', N'under', N'with';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct word: "in" (The fish is ____ the water.)', N'in', N'on', N'of', N'at';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'What are they? (clouds)', N'They are clouds.', N'It is clouds.', N'This is clouds.', N'They is cloud.';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct word: "rainbow" is in the _____.', N'sky', N'bag', N'book', N'desk';
EXEC #AddQuiz N'Lớp 3 - Unit 2', N'Choose the correct animal: It can fly.', N'bird', N'fish', N'frog', N'turtle';


PRINT N'--- Đang nạp Unit 3: My Family ---';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Who is this? (mother)', N'She is my mother.', N'He is my mother.', N'She is my father.', N'It is my mother.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Who is this? (father)', N'He is my father.', N'She is my father.', N'He is my sister.', N'They are my father.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Who is she? (sister)', N'She is my sister.', N'He is my sister.', N'She is my brother.', N'It is my sister.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Who is he? (brother)', N'He is my brother.', N'She is my brother.', N'He is my mother.', N'It is my brother.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'How many brothers do you have? (2)', N'I have two brothers.', N'I have two brother.', N'I has two brothers.', N'I have brothers two.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'How many sisters do you have? (1)', N'I have one sister.', N'I have one sisters.', N'I has one sister.', N'I have sister one.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'My ____ is old. (grandfather)', N'grandfather', N'grandmother', N'brother', N'sister';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'My ____ is kind. (grandmother)', N'grandmother', N'grandfather', N'father', N'mother';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'This is ____ family.', N'my', N'I', N'me', N'mine';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'I love my _____.', N'parents', N'pencils', N'windows', N'clouds';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Choose the correct sentence.', N'My family is big.', N'My family are big.', N'My family big is.', N'Family my is big.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Choose the correct pronoun: mother -> ____', N'she', N'he', N'it', N'they';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Choose the correct pronoun: father -> ____', N'he', N'she', N'it', N'they';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'We are happy _____.', N'together', N'tomorrow', N'turtle', N'table';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Choose the correct word: "This is ____ (Lan)."', N'Lan', N'her', N'she', N'they';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Choose the correct question: ask a person.', N'Who is he?', N'What is he?', N'Where is he?', N'How is he old?';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Choose the correct answer: "Who is she?"', N'She is my mother.', N'It is a chair.', N'In the kitchen.', N'It is red.';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'Choose the correct word: brother/sister are _____.', N'children', N'parents', N'grandparents', N'teachers';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'My brother is _____. (tall)', N'tall', N'table', N'taste', N'time';
EXEC #AddQuiz N'Lớp 3 - Unit 3', N'My sister is _____. (young)', N'young', N'yellow', N'yesterday', N'yummy';


PRINT N'--- Đang nạp Unit 4: My House ---';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Where are you?', N'I am at home.', N'I am eight.', N'It is a pen.', N'Yes, it is.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Where are you? (living room)', N'I am in the living room.', N'I am on the living room.', N'I am living room.', N'I am at living room.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Choose the room for sleeping.', N'bedroom', N'kitchen', N'bathroom', N'classroom';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Choose the room for cooking.', N'kitchen', N'bedroom', N'library', N'gym';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Is there a lamp in the bedroom?', N'Yes, there is.', N'Yes, it is.', N'Yes, they are.', N'Yes, I do.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Are there any chairs in the kitchen? (No)', N'No, there are not.', N'No, it is not.', N'No, I do not.', N'No, she is not.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'What are you doing? (cook)', N'I am cooking.', N'I cooking am.', N'I am cook.', N'I cooked.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'What are you doing? (clean)', N'I am cleaning.', N'I am clean.', N'I cleaned.', N'I am cleans.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'What is she doing?', N'She is watching TV.', N'She watching TV.', N'She is watch TV.', N'She watched TV.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'What is he doing?', N'He is washing dishes.', N'He washing dishes.', N'He is wash dishes.', N'He washed dish.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Choose the correct preposition: The cat is ____ the table. (under)', N'under', N'on', N'in', N'with';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Choose the correct preposition: The book is ____ the desk. (on)', N'on', N'under', N'in', N'behind';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'The kitchen is _____.', N'small', N'smell', N'smile', N'smart';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'The bedroom is _____.', N'big', N'bag', N'bug', N'bus';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Choose the correct sentence.', N'This is my house.', N'This are my house.', N'These is my house.', N'This is my houses.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'I love my _____.', N'home', N'helmet', N'honey', N'happy';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Choose "There is" for ____ noun.', N'one', N'many', N'two', N'three';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Choose "There are" for ____ noun.', N'many', N'one', N'a', N'an';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Is there a sofa?', N'Yes, there is.', N'Yes, there are.', N'Yes, I am.', N'Yes, they do.';
EXEC #AddQuiz N'Lớp 3 - Unit 4', N'Are there two windows?', N'Yes, there are.', N'Yes, there is.', N'Yes, I am.', N'Yes, it is.';


PRINT N'--- Đang nạp Unit 5: Clothes ---';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'What are you wearing?', N'I am wearing a jacket.', N'I am wear a jacket.', N'I wearing am a jacket.', N'I wore a jacket.';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Choose the correct word: shoes', N'shoes', N'shooes', N'shoos', N'shoose';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Are you wearing a hat? (Yes)', N'Yes, I am.', N'Yes, I do.', N'Yes, it is.', N'Yes, they are.';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Are you wearing gloves? (No)', N'No, I am not.', N'No, I do not.', N'No, it is not.', N'No, they are not.';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'This is my _____. (scarf)', N'scarf', N'sky', N'school', N'soup';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Those are my _____. (socks)', N'socks', N'stocks', N'stars', N'stops';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'These are my _____. (boots)', N'boots', N'books', N'birds', N'balls';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'He has a blue _____.', N'shirt', N'short', N'shark', N'shelf';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'She has a red _____.', N'skirt', N'sky', N'skill', N'skull';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'The jacket is _____.', N'warm', N'water', N'wash', N'wall';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Choose the correct color.', N'black', N'block', N'blank', N'blink';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Put your clothes in the _____.', N'closet', N'cloud', N'class', N'clap';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'I have a new _____. (dress)', N'dress', N'desk', N'dream', N'drink';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Choose the correct sentence.', N'I am wearing shoes.', N'I am wearing shoe.', N'I wear wearing shoes.', N'I wearing shoes am.';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Choose the correct question.', N'What are you wearing?', N'What you are wearing?', N'Wearing what are you?', N'What wearing you are?';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'The hat is _____. (nice)', N'nice', N'nine', N'net', N'new';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'I like my _____.', N'clothes', N'clouds', N'classes', N'closes';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Choose the correct word: "a ____ of shoes" (pair)', N'pair', N'piece', N'loaf', N'bottle';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Choose the correct answer: "What color is your shirt?"', N'It is blue.', N'It is a shirt.', N'Yes, it is.', N'I am fine.';
EXEC #AddQuiz N'Lớp 3 - Unit 5', N'Let us go _____.', N'outside', N'inside', N'under', N'behind';


PRINT N'--- Đang nạp Unit 6: Toys ---';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'What do you want?', N'I want a ball.', N'I want ball a.', N'I am want a ball.', N'I wanted a ball.';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Do you want a robot? (Yes)', N'Yes, I do.', N'Yes, I am.', N'Yes, it is.', N'Yes, there is.';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Do you want a doll? (No)', N'No, I do not.', N'No, I am not.', N'No, it is not.', N'No, there are not.';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Is this your teddy bear? (Yes)', N'Yes, it is.', N'Yes, I do.', N'Yes, they are.', N'Yes, I am.';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Are these your balls? (Yes)', N'Yes, they are.', N'Yes, it is.', N'Yes, I do.', N'Yes, I am.';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Are these your trains? (No)', N'No, they are not.', N'No, it is not.', N'No, I do not.', N'No, I am not.';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'I have a new _____. (puzzle)', N'puzzle', N'purple', N'pocket', N'people';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'The robot is _____.', N'cool', N'cook', N'cold', N'cloud';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'The doll is _____.', N'pretty', N'prey', N'price', N'print';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct toy: It can fly in the sky.', N'kite', N'ball', N'doll', N'robot';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct toy: You can kick it.', N'ball', N'kite', N'doll', N'puzzle';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct sentence.', N'Let us play together.', N'Let play us together.', N'Let us together play.', N'Let together us play.';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct word: "This is ____ toy."', N'my', N'me', N'I', N'mine';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct question for one thing.', N'Is this your car?', N'Are this your car?', N'Is these your car?', N'Are those your car?';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct question for many things.', N'Are these your toys?', N'Is these your toys?', N'Are this your toys?', N'Is that your toys?';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct answer: "Here you are."', N'Thank you.', N'How are you?', N'Good night.', N'What is this?';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct word: "toy" plural is _____.', N'toys', N'toyes', N'toies', N'toy';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'I want ____ robot.', N'a', N'an', N'some', N'any';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'I want ____ apples. (many)', N'some', N'a', N'an', N'is';
EXEC #AddQuiz N'Lớp 3 - Unit 6', N'Choose the correct word: teddy ____', N'bear', N'beer', N'bean', N'beak';


PRINT N'--- Đang nạp Unit 7: My Body ---';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'This is my _____. (head)', N'head', N'heart', N'heat', N'hand';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'These are my _____. (hands)', N'hands', N'hand', N'heads', N'hairs';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'These are my _____. (feet)', N'feet', N'foots', N'foot', N'fits';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'He has curly _____.', N'hair', N'hear', N'here', N'heart';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'She has straight _____.', N'hair', N'hat', N'hand', N'head';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'His eyes are _____. (brown)', N'brown', N'blue', N'green', N'yellow';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Can you run?', N'Yes, I can.', N'Yes, I do.', N'Yes, I am.', N'Yes, it is.';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Can you jump? (No)', N'No, I cannot.', N'No, I do not.', N'No, I am not.', N'No, it is not.';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Choose the correct sentence.', N'I can swim.', N'I can swims.', N'I am can swim.', N'I swim can.';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Wash your _____.', N'hands', N'ears', N'eyes', N'hair';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Brush your _____.', N'teeth', N'tooth', N'teath', N'trees';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Touch your _____.', N'nose', N'noise', N'notes', N'neck';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Clap your _____.', N'hands', N'head', N'feet', N'eyes';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Stamp your _____.', N'feet', N'hands', N'eyes', N'nose';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Choose the correct sentence.', N'My body is strong.', N'My body are strong.', N'My body strong is.', N'Body my is strong.';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'We should exercise every _____.', N'day', N'dog', N'desk', N'door';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Choose the body part: we see with our _____.', N'eyes', N'ears', N'nose', N'hands';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Choose the body part: we hear with our _____.', N'ears', N'eyes', N'mouth', N'feet';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Choose the body part: we smell with our _____.', N'nose', N'eyes', N'ears', N'hands';
EXEC #AddQuiz N'Lớp 3 - Unit 7', N'Choose the correct word: "mouth"', N'mouth', N'mouse', N'month', N'math';


PRINT N'--- Đang nạp Unit 8: Food & Drinks ---';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'What is your favorite food?', N'I like apples.', N'I am apples.', N'It is apples.', N'Yes, I am.';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Do you like bananas? (Yes)', N'Yes, I do.', N'Yes, I am.', N'Yes, it is.', N'Yes, there is.';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Do you like fish? (No)', N'No, I do not.', N'No, I am not.', N'No, it is not.', N'No, there are not.';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'I want ____ water.', N'some', N'a', N'an', N'many';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'I drink ____ every day. (milk)', N'milk', N'meal', N'meet', N'make';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'I eat rice for _____.', N'lunch', N'blue', N'chair', N'class';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'There is ____ apple on the table.', N'an', N'a', N'some', N'any';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'There are ____ eggs.', N'some', N'a', N'an', N'is';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Choose the correct: There ____ a banana.', N'is', N'are', N'am', N'be';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Choose the correct: There ____ two bananas.', N'are', N'is', N'am', N'be';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Choose the correct question for uncountable.', N'Is there any water?', N'Are there any water?', N'Is there a water?', N'Are there a water?';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Choose the correct question for countable plural.', N'Are there any cookies?', N'Is there any cookies?', N'Are there a cookies?', N'Is there a cookies?';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Don''t eat too ____ cookies.', N'many', N'much', N'a', N'an';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Don''t drink too ____ soda.', N'much', N'many', N'two', N'few';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Choose the drink.', N'water', N'bread', N'rice', N'egg';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Choose the fruit.', N'apple', N'chicken', N'rice', N'soup';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Choose the correct sentence.', N'Food is good for our health.', N'Food are good for our health.', N'Food good is health.', N'Food is good our for health.';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'He likes _____. (chicken)', N'chicken', N'kitchen', N'children', N'chocolate';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'She likes _____. (fish)', N'fish', N'finish', N'fishes', N'fishing';
EXEC #AddQuiz N'Lớp 3 - Unit 8', N'Let us eat _____.', N'together', N'tomorrow', N'turtle', N'table';

-- XÓA THỦ TỤC TẠM
DROP PROCEDURE #AddQuiz;

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU TRẮC NGHIỆM (ROUND 3) - LỚP 3!';
GO

USE GameHocTiengAnh1;
GO

PRINT N'=== BẮT ĐẦU TẠO DỮ LIỆU ROUND 4 (ĐIỀN TỪ) - LỚP 3 ===';


IF OBJECT_ID('tempdb..#AddFillBlank') IS NOT NULL DROP PROCEDURE #AddFillBlank;
GO

CREATE PROCEDURE #AddFillBlank
    @UnitName NVARCHAR(100),
    @Sentence NVARCHAR(MAX),
    @CorrectAns NVARCHAR(255),
    @Wrong1 NVARCHAR(255),
    @Wrong2 NVARCHAR(255),
    @Wrong3 NVARCHAR(255)
AS
BEGIN
    -- Sửa lại: Tìm tên Topic bắt đầu bằng @UnitName
    DECLARE @TopicID INT = (SELECT TOP 1 TopicID FROM Topics WHERE TopicName LIKE @UnitName + N'%');
    DECLARE @QID INT;

    IF @TopicID IS NOT NULL
    BEGIN
        INSERT INTO Questions (TopicID, QuestionText, QuestionType, CorrectAnswer)
        VALUES (@TopicID, @Sentence, 'fill_in_blank', @CorrectAns);
        
        SET @QID = SCOPE_IDENTITY();

        INSERT INTO QuestionOptions (QuestionID, OptionContent, IsCorrect) VALUES 
        (@QID, @CorrectAns, 1),
        (@QID, @Wrong1, 0),
        (@QID, @Wrong2, 0),
        (@QID, @Wrong3, 0);
    END
    ELSE
    BEGIN
        PRINT N'⚠️ Lỗi: Không tìm thấy Topic tên là: ' + @UnitName;
    END
END;
GO

-- ======================================================================================
-- 3. NẠP DỮ LIỆU (SỬ DỤNG TÊN CHUẨN: 'Lớp 3 - Unit...')
-- ======================================================================================

PRINT N'--- Unit 0: Getting Started ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'The weather is hot in ______.', N'summer', N'winter', N'spring', N'fall';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'Leaves fall from trees in ______.', N'autumn', N'summer', N'spring', N'winter';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'It is ______ and snowy in winter.', N'cold', N'hot', N'warm', N'dry';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'There are twelve ______ in a year.', N'months', N'weeks', N'days', N'seasons';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'My birthday is ______ May.', N'in', N'on', N'at', N'of';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'What is the weather ______ today?', N'like', N'is', N'look', N'love';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'Ten plus ten is ______.', N'twenty', N'thirty', N'ten', N'forty';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'I like to go swimming in the ______ season.', N'dry', N'rainy', N'cold', N'snowy';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'We wear coats when it is ______.', N'cold', N'hot', N'sunny', N'warm';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'______ is the first month.', N'January', N'February', N'December', N'March';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'Flowers bloom in ______.', N'spring', N'winter', N'autumn', N'night';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'One hundred ______ fifty is fifty.', N'minus', N'plus', N'times', N'and';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'Is your birthday in June? - No, it ______.', N'isn''t', N'is', N'not', N'aren''t';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'Do you like sunny weather? - Yes, I ______.', N'do', N'am', N'don''t', N'does';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'The ______ season has a lot of rain.', N'rainy', N'dry', N'hot', N'cold';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'March, April, and May are in ______.', N'spring', N'summer', N'winter', N'fall';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'It is usually ______ in the desert.', N'hot', N'cold', N'wet', N'snowy';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'______ comes after August.', N'September', N'July', N'October', N'June';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'Twenty plus ______ is thirty.', N'ten', N'five', N'twenty', N'one';
EXEC #AddFillBlank N'Lớp 3 - Unit 0', N'I make a snowman in ______.', N'winter', N'summer', N'fall', N'spring';

PRINT N'--- Unit 1: Animal Habitats ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'A camel lives in the ______.', N'desert', N'sea', N'forest', N'cave';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Polar bears live in the ______ region.', N'polar', N'hot', N'rainy', N'dry';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Fish swim in the ______.', N'water', N'sky', N'sand', N'tree';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Birds build ______ in trees.', N'nests', N'caves', N'hives', N'holes';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Bees live in a ______.', N'hive', N'nest', N'cave', N'house';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'A giraffe has a long ______.', N'neck', N'nose', N'ear', N'hand';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Elephants use their ______ to drink water.', N'trunks', N'ears', N'tails', N'legs';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'A kangaroo has a ______ for its baby.', N'pouch', N'bag', N'box', N'pocket';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Monkeys can ______ trees.', N'climb', N'fly', N'swim', N'run';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Penguins cannot ______.', N'fly', N'swim', N'walk', N'jump';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Bats sleep in ______ during the day.', N'caves', N'nests', N'hives', N'water';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Crocodiles have sharp ______.', N'teeth', N'hair', N'ears', N'hands';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'The ocean is very ______.', N'deep', N'high', N'tall', N'dry';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Tigers have ______ on their bodies.', N'stripes', N'spots', N'dots', N'squares';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'A ______ moves very slowly.', N'turtle', N'rabbit', N'cat', N'dog';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Hippos like to play in the ______.', N'mud', N'sky', N'tree', N'bed';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Birds have wings and ______.', N'feathers', N'fur', N'scales', N'skin';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Goats have two ______ on their heads.', N'horns', N'tails', N'noses', N'wings';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'We must ______ the animals.', N'protect', N'hurt', N'hit', N'scare';
EXEC #AddFillBlank N'Lớp 3 - Unit 1', N'Sharks live in the ______.', N'ocean', N'river', N'pond', N'pool';

PRINT N'--- Unit 2: Let''s Eat! ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'I would like a ______ of noodles.', N'bowl', N'box', N'bag', N'book';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Can I have a ______ of water?', N'bottle', N'piece', N'loaf', N'slice';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'This lemon tastes ______.', N'sour', N'sweet', N'spicy', N'salty';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Chili peppers are very ______.', N'spicy', N'sweet', N'cold', N'bitter';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'I want a ______ of cereal.', N'box', N'bottle', N'can', N'tube';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Would you like ______ beans?', N'some', N'a', N'an', N'one';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Is there ______ milk in the fridge?', N'any', N'many', N'a', N'some';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'No, there aren''t ______ eggs.', N'any', N'some', N'much', N'little';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Potato chips are usually ______.', N'salty', N'sweet', N'sour', N'bitter';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Candy and chocolate are ______.', N'sweet', N'spicy', N'sour', N'salty';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'May I have a ______ of pizza?', N'slice', N'bowl', N'bottle', N'jar';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'A ______ of bread.', N'loaf', N'can', N'box', N'bottle';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'I am hungry. I want to ______.', N'eat', N'drink', N'sleep', N'run';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'I am thirsty. I need ______.', N'water', N'food', N'bread', N'meat';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Can you pass me the ______?', N'salt', N'rain', N'wind', N'sun';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Do not eat too much ______.', N'sugar', N'water', N'vegetable', N'fruit';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Coffee without milk is ______.', N'bitter', N'sweet', N'salty', N'sour';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'My favorite food is ______.', N'chicken', N'water', N'juice', N'milk';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'We need a ______ of oil.', N'bottle', N'box', N'bag', N'basket';
EXEC #AddFillBlank N'Lớp 3 - Unit 2', N'Let''s make a ______.', N'cake', N'water', N'milk', N'juice';

PRINT N'--- Unit 3: On the Move! ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'I go to school ______ bus.', N'by', N'on', N'in', N'at';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'We walk on the ______.', N'sidewalk', N'street', N'road', N'river';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'My father ______ a car to work.', N'drives', N'rides', N'flies', N'walks';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'I ______ my bicycle in the park.', N'ride', N'drive', N'run', N'fly';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'A ______ flies in the sky.', N'plane', N'bus', N'train', N'boat';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'The ______ runs on tracks.', N'train', N'car', N'bus', N'taxi';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'We took a ______ across the river.', N'ferry', N'bike', N'scooter', N'truck';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'You must ______ at the red light.', N'stop', N'go', N'run', N'walk';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'Always wear a ______ on a motorbike.', N'helmet', N'hat', N'cap', N'mask';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'The subway goes ______ ground.', N'under', N'on', N'above', N'in';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'We get ______ the bus at the station.', N'off', N'out', N'away', N'over';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'How ______ do you ride your bike?', N'often', N'many', N'much', N'time';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'I go to school on ______.', N'foot', N'leg', N'hand', N'head';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'Boats ______ on water.', N'sail', N'drive', N'ride', N'run';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'A helicopter has ______ on top.', N'blades', N'wings', N'wheels', N'doors';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'Is it safe? - Yes, it ______.', N'is', N'isn''t', N'does', N'do';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'Traffic lights have ______ colors.', N'three', N'two', N'four', N'five';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'Green light means ______.', N'go', N'stop', N'wait', N'slow';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'I sit ______ the car.', N'in', N'on', N'at', N'under';
EXEC #AddFillBlank N'Lớp 3 - Unit 3', N'He goes to work ______ motorcycle.', N'by', N'in', N'with', N'at';

PRINT N'--- Unit 4: Our Senses ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'I use my ______ to see.', N'eyes', N'ears', N'nose', N'mouth';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'I use my ______ to hear.', N'ears', N'eyes', N'hands', N'legs';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'I use my nose to ______.', N'smell', N'taste', N'touch', N'look';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The rabbit feels ______.', N'soft', N'hard', N'loud', N'quiet';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The rock feels ______.', N'hard', N'soft', N'sweet', N'sour';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The music is too ______.', N'loud', N'soft', N'tasty', N'smelly';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The flowers look ______.', N'beautiful', N'ugly', N'loud', N'quiet';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The garbage smells ______.', N'bad', N'good', N'nice', N'sweet';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The lemon tastes ______.', N'sour', N'salty', N'spicy', N'hot';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'Did you ______ the thunder?', N'hear', N'smell', N'touch', N'taste';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The rainbow looks ______.', N'colorful', N'loud', N'bad', N'tasty';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'Smoke smells like ______ wood.', N'burnt', N'fresh', N'clean', N'sweet';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'Durian has a strong ______.', N'smell', N'sound', N'look', N'touch';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'Please be ______ in the library.', N'quiet', N'loud', N'noisy', N'fast';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'I touch with my ______.', N'hands', N'eyes', N'ears', N'nose';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The drum sounds ______.', N'loud', N'soft', N'quiet', N'bad';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'Does it taste good? - Yes, it ______.', N'does', N'is', N'do', N'are';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'The pillow is ______.', N'soft', N'hard', N'sharp', N'loud';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'Look ______ the beautiful picture.', N'at', N'in', N'on', N'for';
EXEC #AddFillBlank N'Lớp 3 - Unit 4', N'Blind people cannot ______.', N'see', N'hear', N'smell', N'touch';

PRINT N'--- Unit 5: Our Health ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'What is the ______ with you?', N'matter', N'wrong', N'problem', N'bad';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'I have a ______.', N'headache', N'head', N'happy', N'hungry';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'You should see a ______.', N'doctor', N'teacher', N'farmer', N'driver';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'He has a sore ______.', N'throat', N'hand', N'hair', N'shoe';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'You should ______ some medicine.', N'take', N'eat', N'drink', N'do';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'She has a high ______.', N'fever', N'heat', N'hot', N'cold';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'I have a ______ nose.', N'runny', N'running', N'rainy', N'sunny';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'You should ______ your hands.', N'wash', N'watch', N'play', N'eat';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'Don''t eat too much ______.', N'candy', N'water', N'vegetable', N'rice';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'You should ______ in bed.', N'rest', N'run', N'jump', N'dance';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'My tooth hurts. I have a ______.', N'toothache', N'headache', N'backache', N'earache';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'Drink plenty of ______.', N'water', N'soda', N'coffee', N'tea';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'Exercise is ______ for you.', N'good', N'bad', N'sad', N'sick';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'I ______ feel well.', N'don''t', N'not', N'am', N'isn''t';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'Did you ______ the medicine?', N'take', N'eat', N'drink', N'go';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'I have a stomachache. My ______ hurts.', N'stomach', N'head', N'leg', N'arm';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'You look ______.', N'tired', N'tire', N'tiring', N'sleep';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'You shouldn''t stay up ______.', N'late', N'early', N'morning', N'noon';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'Cover your mouth when you ______.', N'cough', N'laugh', N'smile', N'eat';
EXEC #AddFillBlank N'Lớp 3 - Unit 5', N'Healthy food makes us ______.', N'strong', N'weak', N'sick', N'tired';

PRINT N'--- Unit 6: The World of School ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'We read books in the ______.', N'library', N'gym', N'canteen', N'pool';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'I have math ______ Monday.', N'on', N'in', N'at', N'of';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'My favorite subject is ______.', N'English', N'football', N'game', N'sleep';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'We play sports in the ______.', N'gym', N'library', N'class', N'lab';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'I went to the ______ yesterday.', N'zoo', N'go', N'goes', N'going';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'Did you ______ a video?', N'make', N'do', N'play', N'go';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'I use a ______ in IT class.', N'computer', N'ball', N'book', N'pen';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'We learn about the past in ______.', N'history', N'math', N'music', N'art';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'I draw pictures in ______ class.', N'art', N'math', N'PE', N'IT';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'Our school has a big ______.', N'playground', N'play', N'playing', N'played';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'My teacher is very ______.', N'kind', N'bad', N'angry', N'sad';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'We wear a ______ at school.', N'uniform', N'costume', N'pyjama', N'hat';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'I joined a science ______.', N'club', N'class', N'room', N'house';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'What ______ do you have today?', N'subjects', N'games', N'toys', N'food';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'I like to ______ the piano.', N'play', N'do', N'make', N'go';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'We eat lunch in the ______.', N'canteen', N'library', N'gym', N'lab';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'I do my ______ after school.', N'homework', N'housework', N'play', N'sleep';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'Did you go to school? - Yes, I ______.', N'did', N'do', N'does', N'done';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'We learn to sing in ______ class.', N'music', N'math', N'art', N'PE';
EXEC #AddFillBlank N'Lớp 3 - Unit 6', N'The school year starts in ______.', N'September', N'July', N'May', N'January';

PRINT N'--- Unit 7: The World of Work ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A ______ teaches students.', N'teacher', N'doctor', N'farmer', N'driver';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A doctor works in a ______.', N'hospital', N'school', N'farm', N'shop';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A ______ flies a plane.', N'pilot', N'driver', N'rider', N'worker';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'What do you want to ______?', N'be', N'do', N'make', N'have';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'I want to be a ______.', N'singer', N'sing', N'song', N'singing';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A farmer grows ______.', N'vegetables', N'cars', N'houses', N'clothes';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A ______ puts out fires.', N'firefighter', N'teacher', N'doctor', N'cook';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A chef ______ food.', N'cooks', N'eats', N'buys', N'sells';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A ______ builds houses.', N'builder', N'teacher', N'nurse', N'artist';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'An artist paints ______.', N'pictures', N'walls', N'cars', N'floors';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A vet helps sick ______.', N'animals', N'people', N'cars', N'computers';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A dentist fixes ______.', N'teeth', N'hair', N'eyes', N'ears';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A police officer ______ us safe.', N'keeps', N'makes', N'does', N'has';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'He works very ______.', N'hard', N'bad', N'lazy', N'slow';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A salesperson works in a ______.', N'shop', N'school', N'hospital', N'farm';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'I want to ______ people.', N'help', N'hurt', N'hit', N'sad';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A mechanic fixes ______.', N'cars', N'teeth', N'people', N'food';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'A baker makes ______.', N'bread', N'meat', N'fruit', N'soup';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'What does your father ______?', N'do', N'be', N'make', N'work';
EXEC #AddFillBlank N'Lớp 3 - Unit 7', N'She wants to be a famous ______.', N'singer', N'sing', N'sang', N'song';

PRINT N'--- Unit 8: Fantastic Holidays ---';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'We will go to the ______.', N'beach', N'school', N'work', N'hospital';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'I will ______ my grandma.', N'visit', N'see', N'watch', N'look';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'We eat ______ cake at Mid-Autumn.', N'moon', N'sun', N'star', N'sky';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'Children get lucky ______ at Tet.', N'money', N'candy', N'toy', N'book';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'We will stay at a ______.', N'hotel', N'school', N'shop', N'park';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'Go ______ and turn left.', N'straight', N'street', N'right', N'back';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'The market is on your ______.', N'right', N'write', N'white', N'light';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'I will buy some ______.', N'souvenirs', N'money', N'hotel', N'beach';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'We decorate the house ______ Tet.', N'before', N'after', N'during', N'when';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'Santa Claus comes at ______.', N'Christmas', N'Tet', N'Easter', N'Halloween';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'We watch a ______ dance.', N'lion', N'tiger', N'cat', N'dog';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'I will ______ a sandcastle.', N'build', N'make', N'do', N'go';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'Where ______ you go?', N'will', N'do', N'did', N'does';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'It will be ______.', N'fun', N'sad', N'bad', N'boring';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'I wear a ______ for Halloween.', N'costume', N'uniform', N'suit', N'dress';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'We will swim in the ______.', N'sea', N'sky', N'sand', N'mountain';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'Happy New ______!', N'Year', N'Day', N'Month', N'Week';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'I am going to ______ a trip.', N'take', N'do', N'make', N'go';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'See you ______ week.', N'next', N'last', N'past', N'before';
EXEC #AddFillBlank N'Lớp 3 - Unit 8', N'We travel by ______.', N'plane', N'foot', N'walk', N'run';

-- XÓA THỦ TỤC
DROP PROCEDURE #AddFillBlank;

PRINT N'✅ ĐÃ TẠO XONG 180 CÂU ĐIỀN TỪ (20 CÂU x 9 UNIT)!';
GO

-- ==========================================================
-- BỔ SUNG: TẠO DỮ LIỆU CÁC MÀN CHƠI (GAMES)
-- ==========================================================
-- Chỉ chèn nếu chưa có để tránh lỗi trùng lặp
IF NOT EXISTS (SELECT 1 FROM Games WHERE GameID = 1)
    INSERT INTO Games (GameName, GameDescription, TimeLimit, PassScore) VALUES (N'Round 1: Matching', N'Nối từ vựng và nghĩa', 0, 5);

IF NOT EXISTS (SELECT 1 FROM Games WHERE GameID = 2)
    INSERT INTO Games (GameName, GameDescription, TimeLimit, PassScore) VALUES (N'Round 2: Scramble', N'Sắp xếp lại câu', 0, 5);

IF NOT EXISTS (SELECT 1 FROM Games WHERE GameID = 3)
    INSERT INTO Games (GameName, GameDescription, TimeLimit, PassScore) VALUES (N'Round 3: Multiple Choice', N'Trắc nghiệm ABCD', 0, 5);

IF NOT EXISTS (SELECT 1 FROM Games WHERE GameID = 4)
    INSERT INTO Games (GameName, GameDescription, TimeLimit, PassScore) VALUES (N'Round 4: Fill in Blank', N'Điền từ vào chỗ trống', 0, 5);

PRINT N'✅ Đã kiểm tra và tạo 4 Game Round.';
GO

