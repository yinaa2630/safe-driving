import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // 상단 뒤로가기 & 타이틀
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: inkBlack,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "계정 만들기",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: inkBlack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                "빠르게 가입하고 안전하게 운행하세요",
                style: TextStyle(fontSize: 14, color: textMedium),
              ),

              const SizedBox(height: 32),

              _buildInputLabel("이름"),
              _buildInputField(hint: "홍길동"),

              const SizedBox(height: 20),

              _buildInputLabel("이메일"),
              _buildInputField(hint: "[email protected]"),

              const SizedBox(height: 20),

              _buildInputLabel("비밀번호"),
              _buildInputField(hint: "••••••••", obscure: true),

              const SizedBox(height: 20),

              _buildInputLabel("비밀번호 확인"),
              _buildInputField(hint: "••••••••", obscure: true),

              const SizedBox(height: 22),

              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "이용약관 및 개인정보처리방침에 동의합니다",
                      style: TextStyle(fontSize: 13, color: textMedium),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "가입하기",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "이미 계정이 있으신가요? ",
                        style: TextStyle(color: textMedium),
                      ),
                      TextSpan(
                        text: "로그인",
                        style: TextStyle(
                          color: mainGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/');
                          },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildInputLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
  );
}

Widget _buildInputField({required String hint, bool obscure = false}) {
  return Container(
    height: 52,
    decoration: BoxDecoration(
      color: bgWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.center,
    child: TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
      ),
    ),
  );
}
