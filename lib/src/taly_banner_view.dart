import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sdk_flutter/src/utils/taly_assets.dart';
import 'package:sdk_flutter/src/utils/taly_text_styles.dart';
import 'taly_sdk.dart';
import 'enums/environment.dart';
import 'models/installment_model.dart';

const Color _kBannerText = Color(0xFF354250);
const Color _kBannerMessage = Color(0xFF65717D);
const Color _kErrorText = Color(0xFF818C98);
const Color _kInfoTint = Color(0xFF0E85FF);
const Color _kCardStroke = Color(0xFFE3E8ED);

const String _kInfoBaseDev = 'https://widget.dev-taly.io/how-it-works';
const String _kInfoBaseProd = 'https://widget.taly.io/how-it-works';

const String _kErrorMessage =
    'Taly payment is unavailable right now.\n'
    'Sorry for the inconvenience. Try again later.';

class TalyBannerView extends StatefulWidget {
  final String name;

  final int quantity;

  final String amount;

  final String currency;

  final void Function(String url)? onInfoClicked;

  const TalyBannerView({
    super.key,
    this.name = '',
    this.quantity = 1,
    required this.amount,
    required this.currency,
    this.onInfoClicked,
  });

  @override
  State<TalyBannerView> createState() => _TalyBannerViewState();
}

class _TalyBannerViewState extends State<TalyBannerView> {
  _BannerState _state = _BannerState.loading;
  InstallmentModel? _firstInstallment;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(TalyBannerView old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount ||
        old.currency != widget.currency ||
        old.quantity != widget.quantity) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (widget.amount.isEmpty || widget.currency.isEmpty) {
      setState(() => _state = _BannerState.error);
      return;
    }
    if (widget.quantity <= 0) {
      setState(() => _state = _BannerState.error);
      return;
    }

    setState(() => _state = _BannerState.loading);

    try {
      final installments = await TalyFlutterSdk.fetchInstallments(
        name: widget.name,
        quantity: widget.quantity,
        amount: widget.amount,
        currency: widget.currency,
      );

      if (!mounted) return;

      if (installments.isEmpty) {
        setState(() => _state = _BannerState.error);
        return;
      }

      setState(() {
        _firstInstallment = installments.first;
        _state = _BannerState.banner;
      });
    } catch (e) {
      log('TalyBannerView fetch error: $e', name: 'TalySDK');
      if (!mounted) return;
      setState(() => _state = _BannerState.error);
    }
  }

  String _buildInfoUrl() {
    final base = TalyFlutterSdk.environment == Environment.development
        ? _kInfoBaseDev
        : _kInfoBaseProd;
    final installmentType = 4;
    return Uri.parse(base).replace(
      queryParameters: {
        'price': widget.amount,
        'installmenttype': '$installmentType',
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _BannerState.loading => _buildLoader(),
      _BannerState.banner => _buildBanner(),
      _BannerState.error => _buildError(),
    };
  }

  Widget _buildLoader() {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kCardStroke),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: SizedBox(
          width: 35,
          height: 35,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF0E85FF),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final inst = _firstInstallment!;
    final message = 'Split into 4 payments of ${inst.currency} ${inst.amount}';

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E8ED)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _TalyLogo(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TalyTextStyles.semiBold600(
                    fontSize: 14,
                    color: _kBannerText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '0% interest, 100% Shariah-compliant.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TalyTextStyles.medium500(
                    fontSize: 12,
                    color: _kBannerMessage,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => widget.onInfoClicked?.call(_buildInfoUrl()),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: SvgPicture.asset(
                TalyIcons.info,
                package: TalyAssets.pkg,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(_kInfoTint, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8ED)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                TalyImages.errorIcon,
                package: TalyAssets.pkg,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: _kErrorText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _kErrorMessage,
            textAlign: TextAlign.center,
            style: TalyTextStyles.medium500(
              fontSize: 14,
              color: _kErrorText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TalyLogo extends StatelessWidget {
  const _TalyLogo();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      TalyIcons.logo,
      package: TalyAssets.pkg,
      width: 44,
      height: 20,
    );
  }
}

enum _BannerState { loading, banner, error }