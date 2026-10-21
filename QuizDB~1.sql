CREATE TABLE STUDENT (
    student_id NUMBER PRIMARY KEY,
    student_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100)
);

INSERT INTO STUDENT VALUES (1, 'Shivam', 'shivam@gmail.com');

INSERT INTO STUDENT VALUES (2, 'Rahul', 'rahul@gmail.com');

INSERT INTO STUDENT VALUES (3, 'Aman', 'aman@gmail.com');

COMMIT;

SELECT * FROM STUDENT;

CREATE TABLE QUIZ (
    quiz_id NUMBER PRIMARY KEY,
    quiz_name VARCHAR2(100) NOT NULL,
    total_questions NUMBER
);

INSERT INTO QUIZ VALUES (101, 'PL/SQL Basics', 5);

INSERT INTO QUIZ VALUES (102, 'SQL Basics', 5);

COMMIT;

SELECT * FROM QUIZ;

CREATE TABLE QUESTION (
    question_id NUMBER PRIMARY KEY,
    quiz_id NUMBER REFERENCES QUIZ(quiz_id),
    question_text VARCHAR2(300) NOT NULL,
    option_a VARCHAR2(100),
    option_b VARCHAR2(100),
    option_c VARCHAR2(100),
    option_d VARCHAR2(100),
    correct_option CHAR(1)
);

INSERT INTO QUESTION VALUES (
    1, 101, 'Which command is used to create a table?',
    'CREATE', 'INSERT', 'UPDATE', 'DELETE', 'A'
);

INSERT INTO QUESTION VALUES (
    2, 101, 'Which PL/SQL section handles errors?',
    'DECLARE', 'BEGIN', 'EXCEPTION', 'END', 'C'
);

INSERT INTO QUESTION VALUES (
    3, 101, 'Which keyword is used to create a procedure?',
    'MAKE', 'CREATE', 'PROCEDURE', 'FUNCTION', 'B'
);

INSERT INTO QUESTION VALUES (
    4, 101, 'Which symbol ends a PL/SQL statement?',
    ':', ';', '.', ',', 'B'
);

INSERT INTO QUESTION VALUES (
    5, 101, 'Which command retrieves data from a table?',
    'GET', 'SHOW', 'SELECT', 'DISPLAY', 'C'
);

COMMIT;

SELECT question_id, quiz_id, question_text, correct_option
FROM QUESTION
ORDER BY question_id; 

CREATE TABLE ANSWER (
    answer_id NUMBER PRIMARY KEY,
    student_id NUMBER REFERENCES STUDENT(student_id),
    question_id NUMBER REFERENCES QUESTION(question_id),
    selected_option CHAR(1),
    is_correct CHAR(1)
);

CREATE TABLE RESULT (
    result_id NUMBER PRIMARY KEY,
    student_id NUMBER REFERENCES STUDENT(student_id),
    quiz_id NUMBER REFERENCES QUIZ(quiz_id),
    score NUMBER,
    total_marks NUMBER,
    attempt_date DATE DEFAULT SYSDATE
);

CREATE OR REPLACE PROCEDURE CHECK_ANSWER (
    p_answer_id IN NUMBER,
    p_student_id IN NUMBER,
    p_question_id IN NUMBER,
    p_selected_option IN CHAR
)
AS
    v_correct_option CHAR(1);
    v_is_correct CHAR(1);
BEGIN
    SELECT correct_option
    INTO v_correct_option
    FROM QUESTION
    WHERE question_id = p_question_id;

    IF UPPER(p_selected_option) = v_correct_option THEN
        v_is_correct := 'Y';
    ELSE
        v_is_correct := 'N';
    END IF;

    INSERT INTO ANSWER (
        answer_id, student_id, question_id,
        selected_option, is_correct
    )
    VALUES (
        p_answer_id, p_student_id, p_question_id,
        UPPER(p_selected_option), v_is_correct
    );

    DBMS_OUTPUT.PUT_LINE(
        'Answer recorded. Correct: ' || v_is_correct
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Question not found.');
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Error: Answer ID already exists.');
END;
/

SET SERVEROUTPUT ON;

BEGIN
    CHECK_ANSWER(1, 1, 1, 'A');
END;
/
SELECT * FROM ANSWER;

CREATE OR REPLACE PROCEDURE CALCULATE_RESULT (
    p_result_id IN NUMBER,
    p_student_id IN NUMBER,
    p_quiz_id IN NUMBER
)
AS
    v_score NUMBER;
    v_total NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_score
    FROM ANSWER A
    JOIN QUESTION Q
        ON A.question_id = Q.question_id
    WHERE A.student_id = p_student_id
      AND Q.quiz_id = p_quiz_id
      AND A.is_correct = 'Y';

    SELECT COUNT(*)
    INTO v_total
    FROM QUESTION
    WHERE quiz_id = p_quiz_id;

    INSERT INTO RESULT (
        result_id, student_id, quiz_id,
        score, total_marks, attempt_date
    )
    VALUES (
        p_result_id, p_student_id, p_quiz_id,
        v_score, v_total, SYSDATE
    );

    DBMS_OUTPUT.PUT_LINE(
        'Quiz result saved successfully!'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Score: ' || v_score || ' out of ' || v_total
    );
END;
/

SET SERVEROUTPUT ON;

BEGIN
    CALCULATE_RESULT(1, 1, 101);
END;
/

SELECT * FROM RESULT;

CREATE OR REPLACE FUNCTION CALCULATE_PERCENTAGE (
    p_score IN NUMBER,
    p_total_marks IN NUMBER
)
RETURN NUMBER
AS
BEGIN
    IF p_total_marks = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND((p_score / p_total_marks) * 100, 2);
END;
/

SELECT CALCULATE_PERCENTAGE(1, 5) AS PERCENTAGE
FROM DUAL;

SET SERVEROUTPUT ON;

DECLARE
    CURSOR result_cursor IS
        SELECT result_id, student_id, quiz_id,
               score, total_marks
        FROM RESULT;

    v_result result_cursor%ROWTYPE;
    v_percentage NUMBER;
BEGIN
    OPEN result_cursor;

    LOOP
        FETCH result_cursor INTO v_result;
        EXIT WHEN result_cursor%NOTFOUND;

        v_percentage := CALCULATE_PERCENTAGE(
            v_result.score,
            v_result.total_marks
        );

        DBMS_OUTPUT.PUT_LINE('Result ID: ' || v_result.result_id);
        DBMS_OUTPUT.PUT_LINE('Student ID: ' || v_result.student_id);
        DBMS_OUTPUT.PUT_LINE('Quiz ID: ' || v_result.quiz_id);
        DBMS_OUTPUT.PUT_LINE('Score: ' || v_result.score ||
                             '/' || v_result.total_marks);
        DBMS_OUTPUT.PUT_LINE('Percentage: ' || v_percentage || '%');
        DBMS_OUTPUT.PUT_LINE('-------------------------');
    END LOOP;

    CLOSE result_cursor;
END;
/

CREATE OR REPLACE TRIGGER RESULT_INSERT_TRIGGER
AFTER INSERT ON RESULT
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'New quiz result inserted for Student ID: '
        || :NEW.STUDENT_ID
    );
END;
/

SELECT TRIGGER_NAME, STATUS
FROM USER_TRIGGERS
WHERE TRIGGER_NAME = 'RESULT_INSERT_TRIGGER';

SELECT RESULT_ID, STUDENT_ID, QUIZ_ID, SCORE
FROM RESULT
ORDER BY RESULT_ID;

SELECT RESULT_ID
FROM RESULT;

SET SERVEROUTPUT ON;

INSERT INTO RESULT (
    result_id,
    student_id,
    quiz_id,
    score,
    total_marks,
    attempt_date
)
VALUES (
    2,
    1,
    101,
    1,
    5,
    SYSDATE
);

COMMIT;

SELECT * FROM RESULT;
SELECT * FROM ANSWER;
SELECT * FROM QUESTION;

SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME IN (
    'STUDENT',
    'QUIZ',
    'QUESTION',
    'ANSWER',
    'RESULT',
    'CHECK_ANSWER',
    'CALCULATE_RESULT',
    'CALCULATE_PERCENTAGE',
    'RESULT_INSERT_TRIGGER'
)
ORDER BY OBJECT_TYPE, OBJECT_NAME;