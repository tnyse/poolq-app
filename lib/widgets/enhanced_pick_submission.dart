import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scoring_service.dart';
import '../services/payment_service.dart';
import '../constants.dart';
import '../Provider/homeProvider.dart';
import '../Model/pick_model.dart';
import '../Module/Screen/Home/ManualPaymentScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnhancedPickSubmission extends StatefulWidget {
  final String weekName;
  final List<Map<String, dynamic>> games;

  const EnhancedPickSubmission({
    Key? key,
    required this.weekName,
    required this.games,
  }) : super(key: key);

  @override
  _EnhancedPickSubmissionState createState() => _EnhancedPickSubmissionState();
}

class _EnhancedPickSubmissionState extends State<EnhancedPickSubmission> {
  final ScoringService _scoringService = ScoringService();
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _tiebreakerController = TextEditingController();
  
  List<String> _selectedPicks = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _initializePicks();
    _tiebreakerController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _tiebreakerController.dispose();
    super.dispose();
  }

  void _initializePicks() {
    _selectedPicks = List.filled(widget.games.length, '');
    _validateForm();
  }

  void _validateForm() {
    final hasAllPicks = _selectedPicks.every((pick) => pick.isNotEmpty);
    final hasTiebreaker = _tiebreakerController.text.isNotEmpty;
    final tiebreakerValid = int.tryParse(_tiebreakerController.text) != null;
    
    setState(() {
      _isValid = hasAllPicks && hasTiebreaker && tiebreakerValid;
    });
  }

  void _selectPick(int gameIndex, String teamAbbr) {
    setState(() {
      _selectedPicks[gameIndex] = teamAbbr;
      _validateForm();
    });
  }

  Future<void> _submitPicks() async {
    if (!_isValid) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Validate picks with scoring service
      final isValid = await _scoringService.validatePicks(_selectedPicks, widget.weekName);
      if (!isValid) {
        throw Exception('Invalid picks. Please ensure you have selected exactly one team for each game.');
      }

      // Save picks and create payment entry
      final pickRecordId = await _paymentService.savePicksAndCreatePaymentEntry(
        picks: _selectedPicks,
        tiebreaker: _tiebreakerController.text,
        weekName: widget.weekName,
      );

      // Navigate to payment screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ManualPaymentScreen(
              pickRecordId: pickRecordId,
              weekName: widget.weekName,
              entryFee: PaymentService.ENTRY_FEE,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Picks - Week ${widget.weekName}'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Error message
          if (_errorMessage != null) _buildErrorMessage(),
          
          // Games list
          Expanded(
            child: _buildGamesList(),
          ),
          
          // Tiebreaker section
          _buildTiebreakerSection(),
          
          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final completedPicks = _selectedPicks.where((pick) => pick.isNotEmpty).length;
    final totalGames = widget.games.length;
    final progress = totalGames > 0 ? completedPicks / totalGames : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$completedPicks/$totalGames games',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: widget.games.length,
      itemBuilder: (context, index) {
        final game = widget.games[index];
        final homeTeam = game['fullname'] ?? game['home'] ?? '';
        final awayTeam = game['fullname2'] ?? game['away'] ?? '';
        final homeAbbr = game['abbreviation'] ?? '';
        final awayAbbr = game['abbreviation2'] ?? '';
        final selectedPick = _selectedPicks[index];

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTeamButton(
                        teamName: homeTeam,
                        teamAbbr: homeAbbr,
                        isSelected: selectedPick == homeAbbr,
                        onTap: () => _selectPick(index, homeAbbr),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildTeamButton(
                        teamName: awayTeam,
                        teamAbbr: awayAbbr,
                        isSelected: selectedPick == awayAbbr,
                        onTap: () => _selectPick(index, awayAbbr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamButton({
    required String teamName,
    required String teamAbbr,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Team logo placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  teamAbbr.isNotEmpty ? teamAbbr[0] : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primary : Colors.grey[600],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              teamName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiebreakerSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiebreaker',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Predict the total score of the Monday Night Football game',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _tiebreakerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter total score (e.g., 45)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_football),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isValid && !_isSubmitting ? _submitPicks : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Submitting...'),
                  ],
                )
              : Text(
                  'Submit Picks (\$${PaymentService.ENTRY_FEE})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
} 