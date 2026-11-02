/**
 * Kịch bản Seed dữ liệu giải đấu mẫu cho môi trường Phát triển cục bộ (Development / Emulator).
 *
 * Tự động tạo:
 * 1. Giải đấu mẫu: "Ballhub Super League 2026"
 * 2. Đăng ký và duyệt 4 đội bóng tham gia
 * 3. Tự động sinh lịch thi đấu vòng tròn (Berger tables) với các cặp đấu
 * 4. Cập nhật tỷ số trận đấu mẫu để kiểm tra công cụ tính điểm Bảng xếp hạng (Standings Engine).
 */
const http = require('http');

function req(path, method, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : '';
    const r = http.request(
      {
        hostname: 'localhost',
        port: 5001,
        path: `/api/v1${path}`,
        method,
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
          'x-user-id': 'user_organizer_01',
          'x-user-role': 'organizer',
          'x-user-name': encodeURIComponent('Ban To Chuc Ballhub'),
          ...headers,
        },
      },
      (res) => {
        let resBody = '';
        res.on('data', (chunk) => (resBody += chunk));
        res.on('end', () => {
          try {
            resolve(JSON.parse(resBody));
          } catch (e) {
            resolve(resBody);
          }
        });
      }
    );
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

async function main() {
  console.log('1. Creating tournament in registrationOpen...');
  const now = Date.now();
  const tRes = await req('/tournaments', 'POST', {
    name: 'Ballhub Super League 2026',
    description: 'Giải bóng đá phong trào đỉnh cao tranh cúp vô địch Ballhub.',
    location: 'Sân bóng Gia Định, TP. Hồ Chí Minh',
    startDate: new Date(now + 86400000 * 2).toISOString(),
    endDate: new Date(now + 86400000 * 14).toISOString(),
    registrationDeadline: new Date(now + 86400000).toISOString(),
    maxTeams: 4,
    format: 'roundRobinSingle',
    status: 'registrationOpen',
  });
  console.log('Tournament created:', tRes.data?.id);
  const tId = tRes.data.id;

  console.log('2. Registering teams...');
  const teams = [
    { teamId: 'team_sao_vang', teamName: 'FC Sao Vàng', captainName: 'Trần Đội Trưởng', captainPhone: '0901234567', captainEmail: 'saovang@ballhub.vn', membersCount: 14 },
    { teamId: 'team_rong_do', teamName: 'FC Rồng Đỏ', captainName: 'Lê Đội Trưởng', captainPhone: '0902345678', captainEmail: 'rongdo@ballhub.vn', membersCount: 12 },
    { teamId: 'team_chien_binh', teamName: 'FC Chiến Binh Sài Gòn', captainName: 'Nguyễn Văn Đội Trưởng', captainPhone: '0903456789', captainEmail: 'chienbinh@ballhub.vn', membersCount: 16 },
    { teamId: 'team_cau_vong', teamName: 'FC Cầu Vồng Trẻ', captainName: 'Phạm Văn Đội Trưởng', captainPhone: '0904567890', captainEmail: 'cauvong@ballhub.vn', membersCount: 14 },
  ];

  const regIds = [];
  for (const t of teams) {
    const r = await req(`/tournaments/${tId}/registrations`, 'POST', t, {
      'x-user-id': `captain_${t.teamId}`,
      'x-user-role': 'teamCaptain',
      'x-user-name': encodeURIComponent(t.captainName),
    });
    console.log(`Registered ${t.teamName}:`, r.data?.id, r.error?.message || '');
    if (r.data?.id) regIds.push(r.data.id);
  }

  console.log('3. Approving teams...');
  for (const rid of regIds) {
    await req(`/tournaments/${tId}/registrations/${rid}`, 'PATCH', { status: 'approved' });
  }

  console.log('4. Generating schedule...');
  const schedRes = await req(`/tournaments/${tId}/schedule`, 'POST', { venue: 'Sân bóng Gia Định' });
  console.log(`Generated ${schedRes.data?.length} matches.`);

  console.log('5. Entering match scores...');
  const matches = await req(`/tournaments/${tId}/matches`, 'GET');
  if (matches.data && matches.data.length >= 2) {
    // Match 1: 3 - 1
    const m1 = matches.data[0];
    const r1 = await req(`/matches/${m1.id}/result`, 'PUT', {
      homeScore: 3,
      awayScore: 1,
      status: 'finished',
      isConfirmed: true,
      reason: 'Trận đấu vòng 1 kết thúc thành công',
    });
    console.log(`Score 1: ${m1.homeTeamName} 3 - 1 ${m1.awayTeamName} => success: ${r1.success}`);

    // Match 2: 2 - 2
    const m2 = matches.data[1];
    const r2 = await req(`/matches/${m2.id}/result`, 'PUT', {
      homeScore: 2,
      awayScore: 2,
      status: 'finished',
      isConfirmed: true,
      reason: 'Trận đấu kịch tính hòa 2 - 2',
    });
    console.log(`Score 2: ${m2.homeTeamName} 2 - 2 ${m2.awayTeamName} => success: ${r2.success}`);
  }

  console.log('6. Checking standings:');
  const standings = await req(`/tournaments/${tId}/standings`, 'GET');
  console.log(JSON.stringify(standings.data, null, 2));

  console.log('SEED COMPLETED SUCCESSFULLY!');
}

main().catch(console.error);
