Okay, bắt đầu thôi nhở, tới giai đoạn này thì cũng hay lắm rồi! Trước hết thì mình cũng phải công nhận, mọi người siêng thật ấy.
Vơi lại, đây cũng là lần đầu mình đi làm Tech Lead thử, và cũng như là Architect/Design ở tầng bên trên.
Mà nói thật nhá, mình mới năm 2, chưa học cơ sở dữ liệu hay công nghệ phần mềm, AI và cũng chưa quen dùng API. Vậy mà cái môn Tư duy tính toán nó bắt làm cái ứng dụng du lịch, nói thật chứ nhìn có khác gì "Đồ án tốt nghiệp" đâu.
Hồi ở thư viện ấy, mình có thấy một ông làm game, kiểu game RPG 2D đánh quái lên level đơn giản bằng RPG Maker thôi, vậy mà nó lại là "Đồ án tốt nghiệp" nghe mới sợ chứ!

Thôi thì, đến đây được cũng là hay rồi, bây giờ mình làm nhanh cái MVP nhá, mọi người cố lên :)

Thì trước hết, trong cái Guideline chính (`Guideline.md`) của mình ấy, mình muốn xin lỗi cái vụ `Core Frontend` là optional.
Kiểu theo mình nghĩ ấy, là nếu như Frontend không nặng quá thì khỏi cần Core can thiệp, nhưng mà bây giờ khác rồi.
Phần Frontend không thể cứ giao cho một mình Frontend làm hết được, do còn nhiều phần như Supabase để lấy data, gọi Backend, dùng AI... vâng, không xuể thật.

Vì thế, coi như mình xong phần Backend rồi đi, qua làm Frontend! Đừng lo, mình test hết rồi, backend API hoạt động ổn rồi đấy!

---

Đầu tiên, nói về luồng làm việc, có thể nói là gần giống như của Backend luôn ấy. Chỉ đơn giản là thay vì Backend cung cấp cho Frontend qua API, thì ở đây Frontend cung cấp cho UI/UX những cái "data thật" để nó dùng thay vì Mock Handler, Placeholder như hiện tại.

Chắc nói về vai trò của các bên liên quan trước nhở.

1. UI/UX:
- Tất nhiên là thiết kế giao diện, làm cái mặt tiền.
- Cung cấp cho Frontend và Core biết cần những thông tin gì, các cái Mock Handlers / Placeholder hiện tại để ghép logic vào.

2. Front-end: Gần như Back-end
- Cung cấp cho UI/UX những cái thông tin nó cần.
- Và cung cấp bằng cách dùng Core.

3. Core Front-end:
- Cung cấp cho Front-end những tính năng / thông tin cần.

Đơn giản và ngắn gọn thì là như thế, việc Integrate (Front-end với Back-end/Database) là của Core, Front-end chỉ việc dùng và trích xuất thông tin cho UI/UX nó xài.

