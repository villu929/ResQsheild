import 'package:flutter/material.dart';

class CoordinationLogScreen extends StatefulWidget {
  const CoordinationLogScreen({super.key});

  @override
  State<CoordinationLogScreen> createState() => _CoordinationLogScreenState();
}

class _CoordinationLogScreenState extends State<CoordinationLogScreen> {
  String _selectedAgency = 'All';
  String _selectedStatus = 'All';

  final List<_AuditLogEntry> _allLogs = [
    _AuditLogEntry(
      timestamp: '21:30:14 IST',
      date: 'Today',
      agency: 'NDRF 04 Battalion Command',
      channel: 'Govt Encrypted Radio + API',
      actionTriggered: 'Sector 3 Boat Evacuation Order',
      responseStatus: 'DISPATCHED',
      statusColor: const Color(0xFF16A34A),
      acknowledgedBy: 'Cmdr. R. K. Nair',
      notes: '24 personnel & 6 rescue boats deployed to Aluva riverside.',
    ),
    _AuditLogEntry(
      timestamp: '21:15:00 IST',
      date: 'Today',
      agency: 'District Collectorate Control Room',
      channel: 'Cell Broadcast Center (CBC)',
      actionTriggered: 'District Flood Evacuation Level 2 Alert',
      responseStatus: 'ACKNOWLEDGED',
      statusColor: const Color(0xFF0284C7),
      acknowledgedBy: 'Addl. District Magistrate (ADM)',
      notes: 'Broadcast pushed to 148,500 registered mobile devices.',
    ),
    _AuditLogEntry(
      timestamp: '20:45:22 IST',
      date: 'Today',
      agency: 'Idamalayar Dam Executive Engineers',
      channel: 'Damodar SCADA Network',
      actionTriggered: '12,000 cusecs Controlled Discharge Notice',
      responseStatus: 'ACTION TAKEN',
      statusColor: const Color(0xFF7C3AED),
      acknowledgedBy: 'Chief Dam Safety Officer',
      notes: 'Sluice gates 2 & 3 raised by 0.45m as scheduled.',
    ),
    _AuditLogEntry(
      timestamp: '20:10:48 IST',
      date: 'Today',
      agency: 'State Fire & Rescue Services (Kerala)',
      channel: 'CAD Emergency Dispatch',
      actionTriggered: 'Tree Fall & Road Clearance at NH-32',
      responseStatus: 'COMPLETED',
      statusColor: const Color(0xFF059669),
      acknowledgedBy: 'Station Officer Aluva',
      notes: 'Highland arterial road cleared for emergency medical transit.',
    ),
    _AuditLogEntry(
      timestamp: '19:40:12 IST',
      date: 'Today',
      agency: 'District Medical Officer (Health Dept)',
      channel: 'Health Alert Network',
      actionTriggered: 'Mass Casualty & Snakebite Serum Readiness',
      responseStatus: 'ACKNOWLEDGED',
      statusColor: const Color(0xFF0284C7),
      acknowledgedBy: 'Dr. Joseph Kurian (DMO)',
      notes: '120 emergency beds & mobile medical vans mobilized.',
    ),
    _AuditLogEntry(
      timestamp: '18:55:30 IST',
      date: 'Today',
      agency: 'Kerala State Electricity Board (KSEB)',
      channel: 'Grid Operations Center',
      actionTriggered: 'Substation De-energization Warning',
      responseStatus: 'ACTION TAKEN',
      statusColor: const Color(0xFF7C3AED),
      acknowledgedBy: 'Grid Supervisor',
      notes: 'Power safely isolated in submerged Sector 4 to prevent electrocution.',
    ),
  ];

  List<_AuditLogEntry> get _filteredLogs {
    return _allLogs.where((l) {
      if (_selectedAgency != 'All' && !l.agency.contains(_selectedAgency)) return false;
      if (_selectedStatus != 'All' && l.responseStatus != _selectedStatus) return false;
      return true;
    }).toList();
  }

  void _exportAuditReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.download_done_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Official Agency Coordination Audit Log exported to PDF & CSV.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF013973)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'COORDINATION LOG',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Inter-Agency Accountability & Dispatch Trail',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF007AEB)),
            tooltip: 'Export Audit Log (PDF/CSV)',
            onPressed: _exportAuditReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAgency,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        items: ['All', 'NDRF', 'Collectorate', 'Dam', 'Fire', 'Medical', 'KSEB']
                            .map((a) => DropdownMenuItem(value: a, child: Text('Agency: $a')))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedAgency = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        items: ['All', 'DISPATCHED', 'ACKNOWLEDGED', 'ACTION TAKEN', 'COMPLETED']
                            .map((s) => DropdownMenuItem(value: s, child: Text('Status: $s')))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedStatus = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Text(
                  'SHOWING ${logs.length} AUDIT RECORDS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const Spacer(),
                const Text(
                  'Real-time ISO Audit Trail',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Log List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _logCard(logs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard(_AuditLogEntry l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${l.date} • ${l.timestamp}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: l.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l.responseStatus,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: l.statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.agency,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            'Trigger: ${l.actionTriggered}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF0284C7)),
          ),
          const SizedBox(height: 6),
          Text(
            l.notes,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Channel: ${l.channel}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Ack: ${l.acknowledgedBy}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditLogEntry {
  final String timestamp;
  final String date;
  final String agency;
  final String channel;
  final String actionTriggered;
  final String responseStatus;
  final Color statusColor;
  final String acknowledgedBy;
  final String notes;

  _AuditLogEntry({
    required this.timestamp,
    required this.date,
    required this.agency,
    required this.channel,
    required this.actionTriggered,
    required this.responseStatus,
    required this.statusColor,
    required this.acknowledgedBy,
    required this.notes,
  });
}
