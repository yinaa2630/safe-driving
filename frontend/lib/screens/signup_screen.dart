import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_demo/theme/colors.dart';
import 'package:flutter_demo/utils/phone_number_formatter.dart';
import '../service/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emergencyCallController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _agree = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agree) {
      _showSnack("약관에 동의하세요.");
      return;
    }

    setState(() => _loading = true);

    final errorMessage = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      _emergencyCallController.text.replaceAll('-', '').trim(),
    );

    setState(() => _loading = false);

    if (errorMessage == null) {
      _showSnack("회원가입 성공");
      Navigator.pushReplacementNamed(context, '/');
    } else {
      _showSnack(errorMessage);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: textLight, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: inkBlack,
                            ),
                            onPressed: () => Navigator.pop(context),
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

                      const SizedBox(height: 32),

                      _buildInputLabel("이름"),
                      _buildInputField(
                        controller: _nameController,
                        hint: "이름 입력",
                        validator: (v) =>
                            v == null || v.isEmpty ? "이름을 입력하세요" : null,
                      ),

                      const SizedBox(height: 20),

                      _buildInputLabel("이메일"),
                      _buildInputField(
                        controller: _emailController,
                        hint: "이메일 주소 입력",
                        validator: (v) => v != null && v.contains("@")
                            ? null
                            : "이메일 형식이 아닙니다",
                      ),

                      const SizedBox(height: 20),

                      _buildInputLabel("비밀번호"),
                      _buildInputField(
                        controller: _passwordController,
                        hint: "비밀번호 입력",
                        obscure: true,
                        validator: (v) =>
                            v != null && v.length >= 4 ? null : "4자 이상 입력하세요",
                      ),

                      const SizedBox(height: 20),

                      _buildInputLabel("비밀번호 확인"),
                      _buildInputField(
                        controller: _confirmController,
                        hint: "비밀번호 재입력",
                        obscure: true,
                        validator: (v) =>
                            v != _passwordController.text ? "비밀번호가 다릅니다" : null,
                      ),

                      const SizedBox(height: 20),

                      _buildInputLabel("비상연락처"),
                      _buildInputField(
                        controller: _emergencyCallController,
                        hint: "비상연락처를 입력하세요",
                        obscure: false,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          PhoneNumberFormatter(),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "번호를 입력하세요";
                          }

                          final phoneReg = RegExp(r'^01[0-9]-\d{3,4}-\d{4}$');

                          if (!phoneReg.hasMatch(v)) {
                            return "올바른 번호 형식이 아닙니다";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Checkbox(
                            activeColor: mainGreen,
                            checkColor: bgWhite,
                            value: _agree,
                            onChanged: (v) {
                              setState(() => _agree = v ?? false);
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "이용약관 및 개인정보처리방침에 동의합니다",
                              style: TextStyle(fontSize: 13, color: textMedium),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(
                                text: "이미 계정이 있으신가요? ",
                                style: TextStyle(color: textMedium),
                              ),
                              TextSpan(
                                text: "로그인",
                                style: const TextStyle(
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

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 고정 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "가입하기",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
