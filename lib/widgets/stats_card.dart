import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final Color accentColor;
  
  const StatsCard({
    Key? key,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.accentColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: currentStreak.toString(),
            label: 'Current Streak',
            color: currentStreak > 0 ? Colors.orange : Colors.grey,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[800],
          ),
          _buildStatItem(
            icon: Icons.emoji_events,
            value: longestStreak.toString(),
            label: 'Longest Streak',
            color: longestStreak >= 7 ? Colors.amber : Colors.grey,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[800],
          ),
          _buildStatItem(
            icon: Icons.percent,
            value: '${(completionRate * 100).toInt()}%',
            label: 'Success Rate',
            color: completionRate > 0.7 ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}