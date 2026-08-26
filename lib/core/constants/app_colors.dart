import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // 생성자를 private로 설정

  // ── 배경 ─────────────────────────────────────────
  static const Color warmCream    = Color(0xFFFFF8F0); // 앱 전반 배경
  static const Color surfaceCard  = Color(0xFFFFF3E4); // 카드 배경
  static const Color surfaceMuted = Color(0xFFF5EBD8); // 입력창, 비활성 배경

  // ── 주 색상 ──────────────────────────────────────
  static const Color primaryBrown = Color(0xFF6B4F3A); // 버튼, 강조 텍스트
  static const Color primaryLight = Color(0xFF9C7B5E); // 보조 버튼, 아이콘
  static const Color primaryMuted = Color(0xFFD4B896); // 비활성 버튼
  static const Color linkText     = Color(0xFF8B6E5A); // 텍스트 링크

  // ── 텍스트 ───────────────────────────────────────
  static const Color darkGray     = Color(0xFF3D3D3D); // 본문 텍스트
  static const Color textMedium   = Color(0xFF6B6B6B); // 보조 텍스트
  static const Color grayCaption  = Color(0xFFAAAAAA); // 힌트, 라벨, 캡션

  // ── 테두리 / 구분선 ───────────────────────────────
  static const Color inputBorder  = Color(0xFFDDD0C8); // 입력창 테두리
  static const Color divider      = Color(0xFFE8E0D8); // 구분선

  // ── 시스템 ────────────────────────────────────────
  static const Color error        = Color(0xFFE53935); // 에러, 빨간 border
  static const Color success      = Color(0xFF43A047); // 성공, 잔디 초록
  static const Color warning      = Color(0xFFFF8F00); // 경고 배지

  // ── 영양소 상태 ───────────────────────────────────
  static const Color nutrientOk   = Color(0xFF43A047); // 적정
  static const Color nutrientLow  = Color(0xFFFF8F00); // 부족
  static const Color nutrientHigh = Color(0xFFE53935); // 과잉
}