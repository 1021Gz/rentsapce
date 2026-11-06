// ignore_for_file: library_private_types_in_public_api
part of '../../home_page.dart';

extension AdminOperationsPages on _HomePageState {
  Widget _adminModerationCenter() => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ศูนย์ตรวจสอบ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const TabBar(
          tabs: [
            Tab(text: 'ประกาศ'),
            Tab(text: 'รายงาน'),
            Tab(text: 'ข้อพิพาท'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [_approvals(), _reports(), const AdminIssuesPage()],
          ),
        ),
      ],
    ),
  );

  Widget _adminFinanceCenter() => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'การเงินและการจอง',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const TabBar(
          tabs: [
            Tab(text: 'การจอง'),
            Tab(text: 'ตรวจสลิป'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [_adminBookings(), const SlipReviewPage()],
          ),
        ),
      ],
    ),
  );
}
