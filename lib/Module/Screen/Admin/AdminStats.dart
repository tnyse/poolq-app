import 'package:flutter/material.dart';
import 'package:poolqapp/constants.dart';
import 'package:poolqapp/services/nfl_game_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class AdminStats extends StatefulWidget {
  const AdminStats({Key? key}) : super(key: key);

  @override
  State<AdminStats> createState() => _AdminStatsState();
}

class _AdminStatsState extends State<AdminStats> {
  final NFLGameService _gameService = NFLGameService();
  final List<Color> _gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];
  
  // Mock data for statistics
  final Map<String, int> _mockUserPicksData = {
    'REG1': 143,
    'REG2': 152,
    'REG3': 128,
    'REG4': 136,
    'REG5': 118,
    'REG6': 145,
    'REG7': 149,
    'REG8': 132,
    'REG9': 128,
    'REG10': 142,
  };
  
  final Map<String, double> _mockWinRateData = {
    'KC': 0.75,
    'BUF': 0.70,
    'BAL': 0.68,
    'SF': 0.65,
    'PHI': 0.62,
    'DAL': 0.60,
    'DET': 0.58,
    'MIA': 0.55,
  };
  
  final Map<String, int> _mockActiveUsers = {
    'Sunday': 215,
    'Monday': 175,
    'Tuesday': 120,
    'Wednesday': 105,
    'Thursday': 165,
    'Friday': 145,
    'Saturday': 155,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Overview'),
          _buildStatsCards(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('User Picks by Week'),
          _buildPicksChart(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Most Picked Teams'),
          _buildTeamPopularityList(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Daily Active Users'),
          _buildActiveUsersChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: headingStyle,
      ),
    );
  }
  
  Widget _buildStatsCards() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: '2,547',
          icon: Icons.people,
          color: primary,
        ),
        _buildStatCard(
          title: 'Weekly Active Users',
          value: '1,243',
          icon: Icons.calendar_today,
          color: accent,
        ),
        _buildStatCard(
          title: 'Total Pools',
          value: '156',
          icon: Icons.sports_football,
          color: info,
        ),
        _buildStatCard(
          title: 'Revenue',
          value: '\$15,420',
          icon: Icons.attach_money,
          color: success,
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPicksChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kDefaultRadius),
        boxShadow: const [defaultShadow],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 50,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final weeks = _mockUserPicksData.keys.toList();
                  if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        weeks[value.toInt()].replaceAll('REG', ''),
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade200),
          ),
          minX: 0,
          maxX: _mockUserPicksData.length.toDouble() - 1,
          minY: 0,
          maxY: 200,
          lineBarsData: [
            LineChartBarData(
              spots: _mockUserPicksData.entries
                  .map((entry) => FlSpot(
                        _mockUserPicksData.keys.toList().indexOf(entry.key).toDouble(),
                        entry.value.toDouble(),
                      ))
                  .toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: _gradientColors,
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: _gradientColors
                      .map((color) => color.withOpacity(0.3))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTeamPopularityList() {
    final sortedTeams = _mockWinRateData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kDefaultRadius),
        boxShadow: const [defaultShadow],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedTeams.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final team = sortedTeams[index];
          final percentage = (team.value * 100).toInt();
          
          // Find team data
          final teamData = _gameService.getMockGamesForWeek('REG1').firstWhere(
            (game) => game['abbreviation'] == team.key || game['abbreviation2'] == team.key,
            orElse: () => <String, dynamic>{},
          );
          
          final isTeam1 = teamData['abbreviation'] == team.key;
          final teamName = isTeam1 ? teamData['fullname'] : teamData['fullname2'];
          final teamImage = isTeam1 ? teamData['picture'] : teamData['picture2'];
          
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(teamImage ?? ''),
            ),
            title: Text(teamName ?? team.key),
            subtitle: Text('${team.key} - Win rate: $percentage%'),
            trailing: SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: team.value,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  HSVColor.fromAHSV(
                    1.0,
                    120 * team.value, // Hue: 0 for red, 120 for green
                    0.8, // Saturation
                    0.9, // Value
                  ).toColor(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildActiveUsersChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kDefaultRadius),
        boxShadow: const [defaultShadow],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 250,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final days = _mockActiveUsers.keys.toList();
                return BarTooltipItem(
                  '${days[groupIndex]}: ${rod.toY.round()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final days = _mockActiveUsers.keys.toList();
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        days[value.toInt()].substring(0, 3),
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 38,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            checkToShowHorizontalLine: (value) => value % 50 == 0,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade200),
          ),
          barGroups: _mockActiveUsers.entries
              .map((entry) => BarChartGroupData(
                    x: _mockActiveUsers.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            accent,
                            accent.withOpacity(0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
} 