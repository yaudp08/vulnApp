<%@ page import="java.sql.*, java.io.*, javax.servlet.*, javax.servlet.http.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Database file path (will be created if not exist)
    String dbPath = application.getRealPath("/") + "vulnApp.db";
    String dbUrl = "jdbc:sqlite:" + dbPath;

    // Initialize DB if not already created
    Class.forName("org.sqlite.JDBC");
    Connection conn = DriverManager.getConnection(dbUrl);
    Statement initStmt = conn.createStatement();
    initStmt.execute("CREATE TABLE IF NOT EXISTS users (username TEXT, password TEXT)");
    initStmt.execute("INSERT INTO users (username, password) SELECT 'admin', 'admin' WHERE NOT EXISTS (SELECT 1 FROM users WHERE username='admin')");
    initStmt.close();
%>
<html>
<head>
    <title>Vulnerable JSP App (SQLite)</title>
</head>
<body>
    <h2>Login</h2>
    <form method="POST" action="vulnApp.jsp">
        Username: <input type="text" name="username" /><br/>
        Password: <input type="password" name="password" /><br/>
        <input type="submit" name="login" value="Login" />
    </form>

    <h2>Search</h2>
    <form method="GET" action="vulnApp.jsp">
        Query: <input type="text" name="search" />
        <input type="submit" value="Search" />
    </form>

    <h2>File Upload</h2>
    <form method="POST" action="vulnApp.jsp" enctype="multipart/form-data">
        Upload File: <input type="file" name="uploadFile" />
        <input type="submit" name="upload" value="Upload" />
    </form>

<%
    // --- SQL Injection ---
    if (request.getParameter("login") != null) {
        String user = request.getParameter("username");
        String pass = request.getParameter("password");
        Statement stmt = conn.createStatement();
        String sql = "SELECT * FROM users WHERE username='" + user + "' AND password='" + pass + "'";
        ResultSet rs = stmt.executeQuery(sql);

        if (rs.next()) {
            out.println("<p style='color:green'>Logged in as " + user + "</p>");
        } else {
            out.println("<p style='color:red'>Invalid credentials.</p>");
        }
        rs.close();
        stmt.close();
    }

    // --- XSS ---
    if (request.getParameter("search") != null) {
        String q = request.getParameter("search");
        out.println("<p>You searched for: <b>" + q + "</b></p>");
    }

    // --- File Upload ---
    if (request.getParameter("upload") != null) {
        Part filePart = request.getPart("uploadFile");
        String fileName = filePart.getSubmittedFileName();
        InputStream fileContent = filePart.getInputStream();
        File uploadedFile = new File(application.getRealPath("/") + fileName);
        FileOutputStream fos = new FileOutputStream(uploadedFile);
        byte[] buffer = new byte[1024];
        int len;
        while ((len = fileContent.read(buffer)) > 0) {
            fos.write(buffer, 0, len);
        }
        fos.close();
        out.println("<p style='color:blue'>File uploaded: " + fileName + "</p>");
    }

    // --- Command Injection ---
    String cmd = request.getParameter("cmd");
    if (cmd != null) {
        out.println("<h3>Command Output</h3><pre>");
        Process proc = Runtime.getRuntime().exec(cmd);
        BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream()));
        String line;
        while ((line = reader.readLine()) != null) {
            out.println(line);
        }
        out.println("</pre>");
    }

    conn.close();
%>

    <h2>Command Execution</h2>
    <form method="GET" action="vulnApp.jsp">
        Command: <input type="text" name="cmd" />
        <input type="submit" value="Run" />
    </form>
</body>
</html>


