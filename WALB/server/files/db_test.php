<?php
// 데이터베이스 연결 테스트 스크립트
header('Content-Type: application/json');

// 환경변수 읽기
$db_host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?: 'localhost';
$db_name = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?: 'mydb';
$db_user = $_ENV['DB_USER'] ?? getenv('DB_USER') ?: 'dbadmin';
$db_password = $_ENV['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?: '';
$db_port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?: '5432';

$result = [
    'config' => [
        'host' => $db_host,
        'database' => $db_name,
        'user' => $db_user,
        'port' => $db_port,
        'password_length' => strlen($db_password)
    ],
    'connection_test' => null,
    'error' => null
];

try {
    $dsn = "pgsql:host={$db_host};port={$db_port};dbname={$db_name};charset=utf8";
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_TIMEOUT => 10,
        PDO::ATTR_PERSISTENT => false
    ];
    
    $pdo = new PDO($dsn, $db_user, $db_password, $options);
    
    // 연결 테스트
    $stmt = $pdo->query("SELECT version(), current_database(), current_user");
    $db_info = $stmt->fetch();
    
    $result['connection_test'] = 'SUCCESS';
    $result['database_info'] = $db_info;
    
} catch(PDOException $e) {
    $result['connection_test'] = 'FAILED';
    $result['error'] = $e->getMessage();
    $result['error_codes'] = [
        'SQLSTATE' => $e->getCode(),
        'driver_code' => $e->errorInfo[1] ?? null,
        'driver_message' => $e->errorInfo[2] ?? null
    ];
}

echo json_encode($result, JSON_PRETTY_PRINT);
?>