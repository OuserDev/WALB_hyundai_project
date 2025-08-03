<?php
// .env 파일 로드 함수
function loadEnvFile($envFile) {
    if (!file_exists($envFile)) {
        return;
    }
    
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    
    foreach ($lines as $line) {
        // 주석 라인 무시
        if (strpos(trim($line), '#') === 0) {
            continue;
        }
        
        // KEY=VALUE 형식 파싱
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            
            // 따옴표 제거
            $value = trim($value, '"\'');
            
            // $_ENV와 putenv 둘 다 설정
            $_ENV[$key] = $value;
            putenv("$key=$value");
        }
    }
}

// .env 파일 로드
$env_paths = [
    __DIR__ . '/../../.env',          // Docker 마운트된 위치
    __DIR__ . '/../.env',             // app 디렉토리 내
    __DIR__ . '/../../.env',          // 프로젝트 루트
];

foreach ($env_paths as $env_path) {
    if (file_exists($env_path)) {
        loadEnvFile($env_path);
        break;
    }
}

// RDS 데이터베이스 설정 (환경변수 우선, 기본값 fallback)
$db_host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?: '127.0.0.1';
$db_name = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?: 'mydb';  # simple_blog에서 mydb로 변경
$db_user = $_ENV['DB_USER'] ?? getenv('DB_USER') ?: 'dbadmin';  # blog_user에서 dbadmin으로 변경
$db_password = $_ENV['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?: 'MySecurePassword123!';  # qwer1234에서 변경
$db_port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?: '5432';  # 3306에서 5432로 변경

// 디버그 정보 (개발 환경에서만)
if (($_ENV['APP_DEBUG'] ?? 'false') === 'true') {
    error_log("Database config - Host: $db_host, DB: $db_name, User: $db_user, Port: $db_port");
}

try {
    // 연결 시간 측정 시작
    $connection_start = microtime(true);
    
    // DSN에 연결 최적화 옵션 추가
    $dsn = "pgsql:host={$db_host};port={$db_port};dbname={$db_name};connect_timeout=5;application_name=walb_app;options='--statement_timeout=5000'";
    
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_TIMEOUT => 5,  // 10초에서 5초로 단축
        PDO::ATTR_PERSISTENT => true,  // 연결 풀링을 위해 persistent 연결 활성화
        PDO::PGSQL_ATTR_DISABLE_PREPARES => true  // prepare 오버헤드 제거
    ];
    
    $pdo = new PDO($dsn, $db_user, $db_password, $options);
    
    // PostgreSQL 세션 최적화 설정
    $pdo->exec("SET statement_timeout = '5s'");
    $pdo->exec("SET lock_timeout = '3s'");
    $pdo->exec("SET idle_in_transaction_session_timeout = '30s'");
    $pdo->exec("SET tcp_keepalives_idle = 60");
    $pdo->exec("SET tcp_keepalives_interval = 5");
    $pdo->exec("SET tcp_keepalives_count = 3");
    
    // 연결 테스트 및 시간 측정
    $query_start = microtime(true);
    $pdo->query("SELECT 1");
    $query_time = (microtime(true) - $query_start) * 1000;
    
    $connection_time = (microtime(true) - $connection_start) * 1000;
    
    // 디버그 정보 (개발 환경에서만)
    if (($_ENV['APP_DEBUG'] ?? 'false') === 'true') {
        error_log("DB Connection Time: {$connection_time}ms, Query Time: {$query_time}ms");
    }
    
} catch(PDOException $e) {
    // 상세한 에러 정보 로깅
    error_log("Database connection failed: " . $e->getMessage());
    error_log("Attempted connection to: $dsn with user: $db_user");
    
    // 사용자에게는 간단한 메시지
    die('데이터베이스 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
}
?>