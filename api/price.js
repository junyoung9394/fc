export default function handler(req, res) {
  res.status(501).json({
    message: "넥슨 공식 Open API에는 FC온라인 거래소 상한가 조회 엔드포인트가 공개되어 있지 않습니다.",
  });
}
