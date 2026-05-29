import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme/kkook_theme.dart';
import '../widgets/kkook_auth_card.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.user,
    this.isEditMode = false,
    this.initialConfig,
  });

  final User user;
  final bool isEditMode;
  final UserConfig? initialConfig;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _smokingStartController = TextEditingController();
  final _dailyCountController = TextEditingController();
  final _packPriceController = TextEditingController(text: '4500');
  final _packQuantityController = TextEditingController(text: '20');

  int _currentStep = 0;
  DateTime _quitStartDate = DateTime.now();
  bool _isSaving = false;

  static const int _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    _prefillFromConfig(widget.initialConfig);
  }

  void _prefillFromConfig(UserConfig? config) {
    if (config == null) {
      return;
    }
    _smokingStartController.text = config.smokingStartYear.toString();
    _dailyCountController.text = config.dailyCount.toString();
    _packPriceController.text = config.packPrice.toString();
    _packQuantityController.text = config.packQuantity.toString();
    _quitStartDate = config.quitStartDate;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _smokingStartController.dispose();
    _dailyCountController.dispose();
    _packPriceController.dispose();
    _packQuantityController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    final error = _validateStep(_currentStep);
    if (error != null) {
      _showMessage(error);
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep += 1);
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }

    await _saveAndContinue();
  }

  Future<void> _goBack() async {
    if (_currentStep == 0 || _isSaving) {
      return;
    }
    setState(() => _currentStep -= 1);
    await _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        final year = int.tryParse(_smokingStartController.text.trim());
        if (year == null || year < 1900 || year > DateTime.now().year) {
          return '흡연 시작 연도를 올바르게 입력해 주세요. 예: 2018';
        }
        return null;
      case 1:
        final dailyCount = int.tryParse(_dailyCountController.text.trim());
        if (dailyCount == null || dailyCount <= 0 || dailyCount > 200) {
          return '하루 흡연량을 1~200 사이 숫자로 입력해 주세요.';
        }
        return null;
      case 2:
        final packPrice = int.tryParse(_packPriceController.text.trim());
        if (packPrice == null || packPrice <= 0) {
          return '담배 한 갑 가격을 숫자로 입력해 주세요.';
        }
        return null;
      case 3:
        final packQuantity = int.tryParse(_packQuantityController.text.trim());
        if (packQuantity == null || packQuantity <= 0) {
          return '한 갑 개비 수를 숫자로 입력해 주세요.';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    final existing = widget.initialConfig;
    final config = UserConfig(
      uid: widget.user.uid,
      smokingStartYear: int.parse(_smokingStartController.text.trim()),
      dailyCount: int.parse(_dailyCountController.text.trim()),
      packPrice: int.parse(_packPriceController.text.trim()),
      packQuantity: int.parse(_packQuantityController.text.trim()),
      quitStartDate: _quitStartDate,
      isOnboardingCompleted: true,
      currentMode: existing?.currentMode,
    );

    if (widget.isEditMode) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      unawaited(
        FirestoreService.instance.saveUserConfig(config).catchError((_) {
          // 저장 실패 시 대시보드 복귀 후 스트림/재로드로 복구. pop 이후 context 사용 불가.
        }),
      );
      return;
    }

    try {
      await FirestoreService.instance.saveUserConfig(config);
    } catch (_) {
      if (mounted) {
        _showMessage('저장 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatQuitStartDateTime(DateTime dateTime) {
    final date =
        '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  Future<void> _pickDateAndTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _quitStartDate,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 1),
      helpText: '금연 시작 날짜 선택',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_quitStartDate),
      helpText: '금연 시작 시간 선택',
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _quitStartDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final stepText = '${_currentStep + 1} / $_totalSteps';
    return Scaffold(
      backgroundColor: KkookColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.chevron_left),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: Text(
                        stepText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KkookColors.label,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  color: KkookColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: KkookAuthCard(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _QuestionView(
                        title: '언제부터 흡연하셨나요?',
                        subtitle: '연도만 입력해 주세요.',
                        child: TextField(
                          controller: _smokingStartController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '예: 2018',
                          ),
                        ),
                      ),
                      _QuestionView(
                        title: '하루 평균 몇 개비 피우시나요?',
                        subtitle: '정확하지 않아도 괜찮아요.',
                        child: TextField(
                          controller: _dailyCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '예: 10',
                          ),
                        ),
                      ),
                      _QuestionView(
                        title: '담배 한 갑 가격은 얼마인가요?',
                        subtitle: '절약 금액 계산에 사용됩니다.',
                        child: TextField(
                          controller: _packPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '예: 4500',
                            suffixText: '원',
                          ),
                        ),
                      ),
                      _QuestionView(
                        title: '한 갑에 몇 개비 들어있나요?',
                        subtitle: '대부분 20개비입니다.',
                        child: TextField(
                          controller: _packQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '예: 20',
                            suffixText: '개비',
                          ),
                        ),
                      ),
                      _QuestionView(
                        title: '금연 시작 날짜를 선택해주세요.',
                        subtitle: '날짜와 시간을 함께 선택해 주세요. 정확한 타이머 계산에 사용됩니다.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatQuitStartDateTime(_quitStartDate),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _pickDateAndTime,
                              child: const Text('날짜·시간 선택하기'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _goNext,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? (widget.isEditMode ? '수정 완료' : '완료')
                              : '다음',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: KkookColors.primary,
                  fontSize: 26,
                ),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}
