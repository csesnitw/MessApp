import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dinner_provider.dart';

class SpecialDinnerPage extends StatefulWidget {
  const SpecialDinnerPage({super.key});

  @override
  State<SpecialDinnerPage> createState() => _SpecialDinnerPageState();
}

class _SpecialDinnerPageState extends State<SpecialDinnerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.3,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    try {
      final provider = context.read<DinnerProvider>();
      //await provider.loadToken();
      await provider.fetchStudentDetails();
    } catch (e) {
      debugPrint("Error fetching student details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load details: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _confirmRedeem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Redemption"),
        content: const Text("Do you want to redeem your special dinner token?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DinnerProvider>().redeemDinner();
            },
            child: const Text("Redeem"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DinnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Digital Mess Card")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: provider.photoUrl.isNotEmpty
                          ? NetworkImage(provider.photoUrl)
                          : const AssetImage("assets/profile.png")
                      as ImageProvider,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(provider.rollNo,
                              style: const TextStyle(fontSize: 16)),
                          Text(provider.mess,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 10),
                          if (provider.token)
                            ElevatedButton(
                              onPressed: () => _confirmRedeem(context),
                              child: const Text("Redeem Special Dinner"),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.token)
                Positioned(
                  top: 8,
                  right: 8,
                  child: FadeTransition(
                    opacity: _blinkController,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
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
