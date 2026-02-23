import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_demo/theme/colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: inkBlack,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.visibility_off,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "SAFE DRIVING",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: inkBlack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                "다시 오셨네요\n안전 운전 시작해요",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "계정에 로그인하세요",
                style: TextStyle(fontSize: 14, color: textMedium),
              ),

              const SizedBox(height: 32),

              _buildInputLabel("이메일"),
              _buildInputField(hint: "[email protected]"),

              const SizedBox(height: 20),

              _buildInputLabel("비밀번호"),
              _buildInputField(hint: "••••••••", obscure: true),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "비밀번호를 잊으셨나요?",
                  style: TextStyle(fontSize: 13, color: mainGreen),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/main');
                  },
                  child: const Text(
                    "로그인",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: bgWhite,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 20),
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
                        text: "계정이 없으신가요? ",
                        style: TextStyle(color: textMedium),
                      ),
                      TextSpan(
                        text: "회원가입",
                        style: TextStyle(
                          color: mainGreen,
                          fontWeight: FontWeight.w600, // SemiBold
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/signup');
                          },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
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
