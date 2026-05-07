CREATE DATABASE StudentDB;
USE StudentDB;

-- 1. Bảng Khoa
CREATE TABLE Department (
    DeptID VARCHAR(5) PRIMARY KEY,
    DeptName VARCHAR(50) NOT NULL
);

-- 2. Bảng SinhVien
CREATE TABLE Student (
    StudentID VARCHAR(6) PRIMARY KEY,
    FullName VARCHAR(50),
    Gender VARCHAR(10),
    BirthDate DATE,
    DeptID VARCHAR(5),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

-- 3. Bảng MonHoc
CREATE TABLE Course (
    CourseID VARCHAR(6) PRIMARY KEY,
    CourseName VARCHAR(50),
    Credits INT
);

-- 4. Bảng DangKy
CREATE TABLE Enrollment (
    StudentID VARCHAR(6),
    CourseID VARCHAR(6),
    Score DECIMAL(4,2), 
    PRIMARY KEY (StudentID, CourseID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- Chèn dữ liệu mẫu
INSERT INTO Department VALUES
('IT','Information Technology'),
('BA','Business Administration'),
('ACC','Accounting');

INSERT INTO Student VALUES
('S00001','Nguyen An','Male','2003-05-10','IT'),
('S00002','Tran Binh','Male','2003-06-15','IT'),
('S00003','Le Hoa','Female','2003-08-20','BA'),
('S00004','Pham Minh','Male','2002-12-12','ACC'),
('S00005','Vo Lan','Female','2003-03-01','IT'),
('S00006','Do Hung','Male','2002-11-11','BA'),
('S00007','Nguyen Mai','Female','2003-07-07','ACC'),
('S00008','Tran Phuc','Male','2003-09-09','IT');

INSERT INTO Course VALUES
('C00001', 'Cơ sở lập trình', 3),
('CS102', 'Cấu trúc dữ liệu', 4),
('BA201', 'Quản trị học', 3),
('AC301', 'Kế toán tài chính', 3),
('MA101', 'Toán cao cấp', 4);

INSERT INTO Enrollment (StudentID, CourseID, Score) VALUES
('S00001', 'C00001', 8.5),
('S00001', 'MA101', 7.0),
('S00002', 'C00001', 6.0),
('S00002', 'CS102', 9.0),
('S00005', 'C00001', 9.5),
('S00008', 'CS102', 5.5),
('S00003', 'BA201', 8.0),
('S00003', 'MA101', 6.5),
('S00006', 'BA201', 4.5),
('S00004', 'AC301', 7.5),
('S00007', 'AC301', 8.0),
('S00007', 'MA101', 9.0);

-- PHẦN A – CƠ BẢN (4đ)
-- Câu 1: Tạo View ViewStudentBasic hiển thị: StudentID, FullName, và DeptName. Sau đó viết lệnh truy vấn toàn bộ dữ liệu từ View này.
create view ViewStudentBasic as (
	select s.StudentID, s.FullName, d.DeptName
    from Student s
    join Department d on s.DeptID = d.DeptID
);

select * from ViewStudentBasic;

-- Câu 2: Tạo một Regular Index tên là idxFullName cho cột FullName của bảng Student.
create index idxFullName on Student(FullName);
-- Câu 3: Viết Stored Procedure GetStudentsIT (không có tham số).
--   - Chức năng: Hiển thị toàn bộ sinh viên thuộc khoa "Information Technology" trong bảng Student kết hợp với DeptName từ bảng Department.
--   - Yêu cầu: Gọi procedure bằng lệnh CALL để kiểm tra.
delimiter //
create procedure GetStudentsIT()
begin 
	select s.StudentID, s.FullName, d.DeptName
    from Student s
    join Department d on s.DeptID = d.DeptID
    where d.DeptName like 'Information Technology';
end //
delimiter ;
call GetStudentsIT();

--  PHẦN B – KHÁ (3đ)
-- Câu 4:
--   - a) Tạo View ViewStudentCountByDept hiển thị: DeptName, TotalStudents (số lượng sinh viên của mỗi khoa).
create view ViewStudentCountByDept as(
	select d.DeptID ,d.DeptName ,count(s.StudentID) total_student
    from Student s
    join Department d on s.DeptID = d.DeptID
    group by d.DeptID ,d.DeptName
);
select * from ViewStudentCountByDept;
--   - b) Từ View trên, viết truy vấn hiển thị khoa có nhiều sinh viên nhất.
SELECT *
FROM ViewStudentCountByDept
ORDER BY total_student DESC
LIMIT 1;
-- Câu 5:
--   - a) Viết Stored Procedure GetTopScoreStudent với tham số: IN varCourseID VARCHAR(6).
--   - Chức năng: Hiển thị sinh viên có điểm cao nhất trong môn học được truyền vào.
delimiter //
create procedure GetTopScoreStudent (in varCourseID VARCHAR(6))
begin
    select s.StudentID, s.FullName, e.Score
    from Student s
    join Enrollment e on s.StudentID = e.StudentID
    where e.CourseID = varCourseID
    order by e.Score desc
    limit 1;
end //
delimiter ;
--   - b) Gọi thủ tục trên để tìm sinh viên có điểm cao nhất môn "Database Systems" (C00001).
call GetTopScoreStudent('C00001');


-- PHẦN C – GIỎI (3đ)
-- Câu 6: Quản lý việc cập nhật điểm cho môn Database Systems (C00001) theo các quy tắc sau:
--   1. Chỉ cho phép cập nhật điểm cho sinh viên thuộc khoa IT.
--   2. Nếu điểm mới truyền vào > 10 → tự động gán lại = 10.
--   3. Việc cập nhật phải thực hiện thông qua Stored Procedure.
--   4. Dữ liệu cập nhật phải đảm bảo không vi phạm điều kiện của View.
-- Yêu cầu thực hiện:
--   - a) Tạo VIEW: Tạo View ViewITEnrollmentDB hiển thị các sinh viên thuộc khoa IT đăng ký môn C00001. View phải có ràng buộc WITH CHECK OPTION.
create view ViewITEnrollmentDB as
select e.StudentID, e.CourseID, e.Score, s.DeptID
from Enrollment e
join Student s on e.StudentID = s.StudentID
where s.DeptID = 'IT' and e.CourseID = 'C00001'
with check option;
--   - b) Viết Stored Procedure: Tạo thủ tục UpdateScoreITDB với các tham số:
--     1. IN varStudentID VARCHAR(6)
--     2. INOUT inoutNewScore DECIMAL(4,2)
--     3. Xử lý: Nếu inoutNewScore > 10 → gán lại = 10. Thực hiện cập nhật điểm thông qua View ViewITEnrollmentDB.
delimiter //
create procedure UpdateScoreITDB (
    in varstudentid varchar(6),
    inout inoutnewscore decimal(4,2)
)
begin
    if inoutnewscore > 10 then
        set inoutnewscore = 10;
    end if;
    update ViewITEnrollmentDB
    set score = inoutnewscore
    where studentid = varstudentid;
end //
delimiter ;
--   - c) GỌI THỦ TỤC: Viết lệnh CALL để kiểm tra thủ tục:
--     1. Khai báo biến session để nhận giá trị INOUT.
--     2. Gọi thủ tục để cập nhật điểm cho một sinh viên bất kỳ thuộc khoa IT.
--     3. Sau khi gọi: Hiển thị lại giá trị điểm mới và kiểm tra dữ liệu trong View ViewITEnrollmentDB.
set @my_score = 15.0;
call UpdateScoreITDB('S00001', @my_score);
select @my_score; 




