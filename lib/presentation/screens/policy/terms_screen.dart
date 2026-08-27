import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TermsScreen extends StatefulWidget {
  // readOnly: true → 마이페이지 진입 (동의 버튼 없음)
  // readOnly: false → 회원가입 진입 (스크롤 끝까지 → 동의 버튼 활성화)
  const TermsScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final _scrollController = ScrollController();
  bool _scrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    if (!widget.readOnly) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrolledToBottom) return;
    final pos = _scrollController.position;
    // 스크롤 끝 20px 이내에 도달하면 활성화
    if (pos.pixels >= pos.maxScrollExtent - 20) {
      setState(() => _scrolledToBottom = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: AppColors.warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.darkGray),
          onPressed: () => context.pop(false)
        ),
        title: const Text(
          '개인정보처리방침',
          style: TextStyle(
            color: AppColors.darkGray,
            fontSize: 17,
            fontWeight: FontWeight.w600
          )
        )
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: const _PrivacyPolicyContent()
              ),
            ),
            if (!widget.readOnly) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    if (!_scrolledToBottom)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          '스크롤을 내려 내용을 확인해 주세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grayCaption
                          ),
                          textAlign: TextAlign.center
                        )
                      ),
                    BiaryButton(
                      label: '동의합니다',
                      onPressed: _scrolledToBottom ? () => context.pop(true) : null
                    )
                  ]
                )
              )
            ]
          ]
        )
      )
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyHeader(),
        SizedBox(height: 20),
        _PolicyArticle(
          number: '제1조',
          title: '개인정보의 처리 목적',
          content:
              '서비스는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.\n\n'
              '1. 회원 가입 및 관리: 회원제 서비스 이용에 따른 본인 확인, 개인 식별, 서비스 부정이용 방지\n'
              '2. 서비스 제공: 아이 식단 기록, 영양 분석, 구독 서비스 제공\n'
              '3. 민원 처리: 민원인의 신원 확인, 민원 사항 확인, 처리 결과 통보'
        ),
        _PolicyArticle(
          number: '제2조',
          title: '수집하는 개인정보 항목 및 수집 방법',
          content:
              '보호자 필수: 이메일 주소, 닉네임\n'
              '보호자 선택: 프로필 이미지\n'
              '아이 정보: 이름, 생년월일, 성별\n'
              '아이 정보 선택: 프로필 이미지, 알레르기 메모\n'
              '식단 기록 (미구독 회원): 식품명, 섭취량, 식사 구분 (서비스 품질 개선 목적, 사용자에게 비공개)\n'
              '식단 기록 (구독 회원): 식품명, 섭취량, 식사 메모, 식사 사진\n'
              '자동 수집: 서비스 이용 기록, 접속 로그\n\n'
              '수집 방법: 앱 내 회원가입 및 서비스 이용 시 직접 입력, 소셜 로그인(Google) 연동 시 해당 서비스로부터 제공\n\n'
              '※ 아이 프로필 정보는 보호자가 직접 입력하는 구조이며, 아동에게 직접 개인정보를 수집하지 않습니다.'
        ),
        _PolicyArticle(
          number: '제3조',
          title: '개인정보의 처리 및 보유 기간',
          content:
              '회원 정보: 회원 탈퇴 후 즉시 삭제\n'
              '식단 기록 (미구독 회원): 회원 탈퇴 후 즉시 삭제 (서비스 개선 목적, 비공개 보관)\n'
              '식단 기록 (구독 회원): 회원 탈퇴 후 즉시 삭제\n'
              '서비스 이용 기록: 3개월\n\n'
              '단, 관련 법령에 의해 보존할 필요가 있는 경우에는 해당 법령에서 정한 기간 동안 보존합니다.'
        ),
        _PolicyArticle(
          number: '제4조',
          title: '개인정보의 제3자 제공',
          content:
              '서비스는 정보주체의 개인정보를 제1조(처리 목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등 「개인정보 보호법」 제17조 및 제18조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.\n\n'
              '현재 서비스는 수집한 개인정보를 제3자에게 제공하지 않습니다.'
        ),
        _PolicyArticle(
          number: '제5조',
          title: '개인정보처리 위탁',
          content:
              '서비스는 원활한 서비스 제공을 위해 다음과 같이 개인정보 처리 업무를 위탁합니다.\n\n'
              '• Supabase, Inc. — 서버 데이터 저장 및 인증\n'
              '• Resend, Inc. — 이메일 발송 (비밀번호 재설정)'
        ),
        _PolicyArticle(
          number: '제6조',
          title: '정보주체의 권리·의무 및 행사 방법',
          content:
              '이용자는 개인정보 주체로서 다음과 같은 권리를 행사할 수 있습니다.\n\n'
              '1. 개인정보 열람 요구\n'
              '2. 오류 등이 있을 경우 정정 요구\n'
              '3. 삭제 요구\n'
              '4. 처리 정지 요구\n\n'
              '위 권리는 앱 내 마이페이지 → 개인정보 수정 또는 문의 이메일로 요청하실 수 있습니다.'
        ),
        _PolicyArticle(
          number: '제7조',
          title: '개인정보의 파기',
          content:
              '서비스는 개인정보 보유기간의 경과, 처리 목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.\n\n'
              '• 전자적 파일 형태: 복원이 불가능한 방법으로 영구 삭제\n'
              '• 회원 탈퇴 시: 탈퇴 요청 즉시 모든 개인정보 삭제 처리'
        ),
        _PolicyArticle(
          number: '제8조',
          title: '개인정보의 안전성 확보 조치',
          content:
              '서비스는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.\n\n'
              '1. 접근 제어: Supabase Row Level Security(RLS) 적용으로 본인 데이터만 접근 가능\n'
              '2. 암호화: 비밀번호는 Supabase Auth에 의해 암호화 저장\n'
              '3. 전송 보안: HTTPS/TLS 적용\n'
              '4. 식사 사진: 인증된 사용자만 접근 가능한 비공개 Storage 버킷에 저장'
        ),
        _PolicyArticle(
          number: '제9조',
          title: '개인정보 자동 수집 장치의 설치·운영 및 거부',
          content:
              '서비스는 이용자에게 개별적인 맞춤 서비스를 제공하기 위해 이용 정보를 저장하고 수시로 불러오는 로컬 스토리지(Hive)를 사용합니다.\n\n'
              '• 사용 목적: 게스트 세션 유지, 로컬 임시 데이터 저장\n'
              '• 거부 방법: 앱 삭제 시 자동 삭제'
        ),
        _PolicyArticle(
          number: '제10조',
          title: '개인정보 보호책임자',
          content:
              '서비스는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 관련 불만 처리 및 피해구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.\n\n'
              '• 이메일: (문의 이메일 입력)'
        ),
        _PolicyArticle(
          number: '제11조',
          title: '개인정보처리방침의 변경',
          content:
              '이 개인정보처리방침은 시행일로부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 앱 내 공지사항을 통하여 고지할 것입니다.\n\n'
              '시행일: 출시 전 확정 예정'
        ),
        SizedBox(height: 40)
      ]
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '바이어리(Biary) 개인정보처리방침',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          )
        ),
        SizedBox(height: 8),
        Text(
          '바이어리(Biary) (이하 "서비스")는 「개인정보 보호법」에 따라 이용자의 개인정보를 보호하고, '
          '이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 다음과 같이 개인정보처리방침을 수립·공개합니다.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grayCaption,
            height: 1.6
          )
        )
      ]
    );
  }
}

class _PolicyArticle extends StatelessWidget {
  const _PolicyArticle({
    required this.number,
    required this.title,
    required this.content
  });

  final String number;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number ($title)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray
            )
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkGray,
              height: 1.7
            )
          )
        ]
      )
    );
  }
}
