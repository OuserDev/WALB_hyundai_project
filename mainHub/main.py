import json
import os
from datetime import datetime
import streamlit as st
from components.session_manager import SessionManager
import streamlit.components.v1 as components

# 페이지 설정 추가
st.set_page_config(
    page_title="WALB - 통합 보안 관리 플랫폼",
    page_icon="🛡️",
    layout="wide",  # 이 부분이 중요
    initial_sidebar_state="expanded"
)

def load_connected_accounts():
    """연결된 AWS 계정 목록 로드 (JSON 파일에서)"""
    accounts = []
    if os.path.exists("registered_accounts.json"):
        try:
            with open("registered_accounts.json", "r", encoding="utf-8") as f:
                for line in f:
                    if line.strip():
                        account = json.loads(line.strip())
                        accounts.append(account)
        except Exception as e:
            st.error(f"계정 데이터 로드 오류: {str(e)}")
    
    # 중복 제거 (account_id + cloud_name 조합으로)
    seen = set()
    unique_accounts = []
    for account in accounts:
        key = f"{account.get('account_id', '')}_{account.get('cloud_name', '')}"
        if key not in seen:
            seen.add(key)
            unique_accounts.append(account)
    
    return unique_accounts

def render_account_card(account, index):
    """계정 카드 렌더링"""
    connection_type = "🛡️ Cross-Account Role" if account.get('role_arn') else "🔑 Access Key"
    
    with st.container():
        col1, col2, col3 = st.columns([3, 2, 1])
        
        with col1:
            st.markdown(f"### ☁️ {account.get('cloud_name', 'Unknown')}")
            st.write(f"**계정 ID:** `{account.get('account_id', 'N/A')}`")
            st.write(f"**연결 방식:** {connection_type}")
            st.write(f"**리전:** `{account.get('primary_region', 'N/A')}`")
            
        with col2:
            st.write(f"**담당자:** {account.get('contact_email', 'N/A')}")
            # 연결 상태 (실제 DB 연동 시 상태 필드 추가 필요)
            st.success("🟢 연결됨")
            
        with col3:
            if st.button("📡 모니터링", key=f"monitor_{index}"):
                st.info("모니터링 기능 (준비중)")
            if st.button("🛡️ 항목진단", key=f"diagnosis_{index}"):
                # 선택된 계정 정보를 세션에 저장
                st.session_state.selected_account = account
                st.switch_page("pages/diagnosis.py")

def main():
    
    # 세련된 헤더 렌더링
    header_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
        body {{
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
        }}
        .hero-header {{
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
            color: white;
            padding-bottom: 0;
            padding: 2.5rem 2rem;
            border-radius: 16px;
            margin: 1rem 0 2rem 0;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            position: relative;
            overflow: hidden;
        }}
        .hero-header::before {{
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>');
            opacity: 0.3;
        }}
        .hero-content {{
            position: relative;
            z-index: 2;
            display: flex;
            align-items: center;
            gap: 1.5rem;
        }}
        .hero-icon {{
            font-size: 3.5rem;
            filter: drop-shadow(0 4px 8px rgba(0,0,0,0.2));
            animation: float 3s ease-in-out infinite;
        }}
        .hero-text {{
            flex: 1;
        }}
        .hero-title {{
            font-size: 2.25rem;
            font-weight: 700;
            margin: 0 0 0.5rem 0;
            background: linear-gradient(45deg, #ffffff, #ffe0e0);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            text-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        .hero-subtitle {{
            font-size: 1.1rem;
            opacity: 0.9;
            margin: 0;
            font-weight: 400;
        }}
        .hero-badge {{
            background: rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-radius: 20px;
            padding: 0.5rem 1rem;
            font-size: 0.875rem;
            font-weight: 500;
            display: inline-block;
            margin-top: 0.75rem;
        }}
        .floating-elements {{
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            pointer-events: none;
            overflow: hidden;
        }}
        .floating-circle {{
            position: absolute;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            animation: float-circle 6s ease-in-out infinite;
        }}
        .circle-1 {{
            width: 60px;
            height: 60px;
            top: 20%;
            right: 10%;
            animation-delay: 0s;
        }}
        .circle-2 {{
            width: 40px;
            height: 40px;
            top: 60%;
            right: 20%;
            animation-delay: 2s;
        }}
        .circle-3 {{
            width: 80px;
            height: 80px;
            top: 10%;
            left: 15%;
            animation-delay: 4s;
        }}
        @keyframes float {{
            0%, 100% {{ transform: translateY(0px); }}
            50% {{ transform: translateY(-10px); }}
        }}
        @keyframes float-circle {{
            0%, 100% {{ transform: translateY(0px) scale(1); opacity: 0.3; }}
            50% {{ transform: translateY(-20px) scale(1.1); opacity: 0.6; }}
        }}
        </style>
    </head>
    <body>
        <div class="hero-header">
            <div class="floating-elements">
                <div class="floating-circle circle-1"></div>
                <div class="floating-circle circle-2"></div>
                <div class="floating-circle circle-3"></div>
            </div>
            <div class="hero-content">
                <div class="hero-icon">🛡️</div>
                <div class="hero-text">
                    <h1 class="hero-title">WALB 통합 보안 관리 솔루션</h1>
                    <p class="hero-subtitle">멀티 클라우드 환경의 보안을 하나로 통합 관리하세요.</p>
                </div>
            </div>
        </div>
    </body>
    </html>
    """
    
    # Components로 렌더링
    components.html(header_html, height=200)
    
    # 연결된 계정 섹션
    st.subheader("☁️ 연결된 AWS 계정")
    
    # 계정 로드
    accounts = load_connected_accounts()
    
    if accounts:
        st.info(f"총 **{len(accounts)}개**의 AWS 계정이 연결되어 있습니다.")
        
        # 계정 카드들 표시
        for index, account in enumerate(accounts):
            with st.expander(f"☁️ {account.get('cloud_name', 'Unknown')} ({account.get('account_id', 'N/A')})"):
                render_account_card(account, index)
                
        # 액션 버튼들
        col1, col2, col3 = st.columns([1, 1, 2])
        
        with col1:
            if st.button("🔄 새로고침", type="secondary"):
                st.rerun()
                
        with col2:
            if st.button("➕ 계정 추가", type="primary"):
                SessionManager.reset_connection_data()
                st.switch_page("pages/connection.py")
                
    else:
        st.warning("연결된 AWS 계정이 없습니다.")
        st.markdown("### 🚀 시작하기")
        st.write("WALB 보안 관리를 시작하려면 AWS 계정을 먼저 연결해주세요.")
        
        if st.button("➕ 첫 번째 계정 연결", type="primary", use_container_width=True):
            SessionManager.reset_connection_data()
            st.switch_page("pages/connection.py")
    
    # 구분선
    st.markdown("---")
    
    # 안전한 클라우드 구축 (별도 기능)
    st.subheader("🏗️ 안전한 클라우드 구축")
    st.markdown("""
    **Shift-Left Security 적용** - 사전 보안이 내장된 새로운 AWS 환경을 자동 구축합니다.
    - 🛡️ 사전 보안 내장 인프라
    - 📋 IaC 기반 Terraform 템플릿  
    - ✅ ISMS-P 컴플라이언스 자동 적용
    """)
    
    if st.button("🚀 새 환경 구축 시작", type="primary", use_container_width=True):
        st.info("안전한 클라우드 구축 기능 (준비중)")
        
if __name__ == "__main__":
    main()