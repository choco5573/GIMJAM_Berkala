# Panduan perubahan (dari Claude)

## Cara kerja alur cerita sekarang

Semua urutan cerita ada di satu file: `naratives/Story_Director.gd` (autoload `StoryDirector`).

- Bagian `STEPS` berisi langkah tiap fase & hari, berurutan: cutscene → task → cutscene ...
- Setiap stage cukup memanggil `StoryDirector.enter_room(self, current_room)` di `load_cutscenes()`.
- Director mencari langkah pertama yang belum selesai:
  - kalau ada di ruangan ini → putar cutscene / munculkan task,
  - kalau di ruangan lain → HUD menampilkan "Pergi ke Kamar / Ruang Tamu / Halaman".
- Kalau semua langkah selesai → tulis diary di kamar → hari berikutnya.
- Cutscene dengan `end_day` (makan pasir, setelah UTBK) langsung ganti fase.
- Cutscene dengan `end_game` (Adult hari 8, ayunan) → layar "Tamat" → kembali ke main menu.

Mau ubah urutan? Edit `STEPS`. Mau tambah cutscene? Buat file `.dialogue`, daftarkan di
`Cutscenes_List_Kid/Teen/Adult.gd` (bagian `DIALOGUES`), lalu tambahkan langkahnya di `STEPS`.

## Yang PERLU kamu cek di editor

1. **Posisi task.** Tiap stage sekarang punya Marker2D di node `Tasks`
   (`DeskMark`, `LavaMark`, `FloorMark`, `SwingMark`, `PondMark`, `ClothesMark`, `SweepMark`).
   Posisinya tebakan saya. Geser ke tempat yang pas (meja, kolam, ayunan, dst.).
   Pastikan `DeskMark` tidak menumpuk dengan Diary, karena tombol E akan memicu keduanya.
2. **Floor is Lava.** Kotak aman & kotak tujuan ada di `SAFE_ZONES` / `GOAL_ZONES`
   di `tasks/floor_is_lava_game/Floor_is_Lava_Game_UI.gd`. Angkanya berdasarkan layout ruang tamu.
3. **Portrait.** Nama file belum seragam (`lara_kid_...`, `lara_Teen_...`, `lara_Adut_lightsmile`).
   `balloon.gd` sudah mencoba beberapa pola nama, tapi sebaiknya rename lewat FileSystem Godot
   supaya rapi. Mama/Ibu/Bos belum punya portrait, jadi saat mereka bicara gambar Lara digelapkan.
4. Sprite penanda task masih `icon.svg` (logo Godot). Ganti di masing-masing `*_Task.tscn`.

## Ringkasan perubahan

- `ToDo_list.gd`: data disesuaikan dengan skrip cerita, tambah `reset()`, `get_tasks()`,
  `is_task_done()`. Hari event (Kid 4, Teen 5, Adult 8) sekarang tetap punya key `tasks`.
  (Sebelumnya `{"???" = false}` dan hari `event` tanpa `tasks` bisa membuat error.)
- `Game_Manager.gd`: `load_room()` generik dan `reset_progress()` untuk game baru.
- `Cutscene_Manager.gd`: animasi jalan player saat `move_player`, `fade_out()` / `fade_in()`,
  `player_face()`, `reset()`. Cutscene tanpa folder kamera tetap bisa diputar.
- Semua stage script memakai StoryDirector. Bug `Stage_3_Livingroom` (pintu ke stage 2) diperbaiki.
- Diary & pintu tidak bisa ditekan saat cutscene/minigame. Diary memakai `StoryDirector.is_day_complete()`.
- HUD: baris petunjuk di bawah layar.
- Main menu: Play → `StoryDirector.start_new_game()` (reset + layar "Masa Kecil").
- Semua task wrapper: sinyal umum `task_solved`, sinyal Area2D disambung lewat kode,
  ESC menutup popup, gagal = popup tertutup dan bisa dicoba lagi.
- Minigame yang diselesaikan: Floor is Lava (mendarat di lantai = ulang), Jemur baju (seret 3 baju),
  Rapat online (QTE, butuh 6 dari 8), Assignment (bank soal 10 nomor: PR 3 soal, tutor 5, UTBK semua).
- Carpet car & cleaning tidak lagi langsung `start()` di `_ready()` (sebelumnya popup tidak bisa dibuka
  karena `running` sudah true).
- Dialog baru: Kid hari 2–4, Teen hari 1–5, Adult hari 1–8 (sesuai skrip). Kid hari 1 milikmu hanya
  diperbaiki sedikit (baris "Mama : ..." dobel, `move_npc()` tanpa marker, tag `nuetral`).

## Collision

- Tiap stage punya node `Collisions` (StaticBody2D) berisi kotak-kotak CollisionShape2D:
  tembok, lemari, meja, kasur, sofa, meja tamu, kolam, pagar, tiang ayunan.
  Kotak ini hanya bagian bawah perabot (tempat kaki), jadi Lara bisa berdiri di depan perabot.
  Geser / ubah ukurannya di editor kalau ada yang kurang pas.
- Collision player sekarang kotak kecil di kaki (14x8, posisi y +24), dan player bergerak lewat
  `velocity` + `move_and_slide()` (sebelumnya `position +=`, jadi tembus semuanya).
- Pintu ruang tamu Stage 2 & 3 dipindah ke posisi yang sama dengan Stage 1 (bisa dijangkau).
- `DeskMark` dipindah ke depan meja (215, 172) supaya bisa dijangkau.
- Gerakan dari cutscene (`move_player`) tetap menembus collision, jadi pastikan tujuannya di lantai.

## Ukuran minigame (384x288)

Popup Swing, Office, Cleaning, Fish dan Carpet dulu dibuat untuk layar 1152x648, jadi sebagian keluar layar.
Sekarang panelnya (16,16)-(368,272), font 14-16, dan angka gameplay ikut disesuaikan
(lebar zona ayunan, radius sapu, kecepatan ikan, ukuran mobil, dst.).
Mobil karpet sekarang memakai `assets/sprites/task_sprites/cars.png` (mobil merah = pemain).
Ayunan: gagal sekarang kembali ke level 1 (sebelumnya ke indeks -1 = level terakhir).

## Petak umpet

`tasks/hide_and_seek/hide_and_seek_game_task.gd` sekarang benar-benar minigame:
7 tempat sembunyi bertanda "?" di halaman (posisi di `HIDING_SPOTS`), Mama di salah satunya (acak).
Datangi tanda, tekan E. Salah = tanda jadi "x", ketemu = task selesai.

## Aset visual (VISART)

- **Portrait VN**: `assets/sprites/characters_sprites/portraits_vn/` (sudah diperkecil dari file asli).
  Nama file: `<nama>_<fase>_<ekspresi>.png`, contoh `lara_kid_happy`, `mama_teen_worried`, `keisha_kid_bengong`.
  Lara dewasa punya dua set: `lara_adult_office_*` (dipakai saat di kamar) dan `lara_adult_home_*` (ruangan lain).
  Mama dan Ibu memakai gambar `mama_<fase>_*` (ekspresi: neutral, smile, worried, scarysmile).
  Tag di dialog = ekspresi, misalnya `Mama: ... [#worried]`. Semua baris Mama/Ibu sudah diberi tag.
- **Kotak dialog**: `VNMODECHATBOX.png` + font VT323 (`assets/fonts/`). VT323 juga jadi font default proyek
  (Project Settings > GUI > Theme > Custom Font).
- **Minigame**:
  - Mobil karpet: `assets/tasks/carpet_car/bombocar.png` (mobil 1 = pemain, 2-4 = rintangan).
  - Kasih makan ikan: ikan, kotak pakan "Takari", butiran pakan, air kolam (`assets/tasks/fish_feeding/`).
  - Floor is Lava: tile lava menutupi lantai (lantai bata tetap aman).
  - Ayunan: animasi Lara berayun (`assets/tasks/swing/swing_anim_0-3.png`, disusun dari frame asli
    supaya titik gantungan pas). Fase remaja hanya menampilkan rangka ayunan (belum ada gambar Lara remaja berayun).
  - PR: latar kertas `tugas.png`. Tutor online & UTBK: layar `utbk.png`. Rapat online: layar `utbk.png`.
  - Tugas kantor & lembur: layar `kerja.png`.
- **Pause menu** (autoload `PauseMenu`): ESC saat jalan di stage. Continue, Settings (layar penuh on/off), Quit (ke main menu).
- Aset ruang tamu tambahan (sofa_2, sofa_3, biscuit, dll.) disalin ke `assets/scenes/living_room/extra/`, belum dipasang.

## Mama di cutscene

- `scenes/npc/Mama_NPC.tscn` + `Npc.gd`. Muncul di cutscene masa kecil lewat perintah dialog:
  `do CutsceneManager.show_mama(x, y, "left")`, `mama_walk_to(x, y, durasi)`, `mama_face("right")`, `hide_mama()`.
  Mama otomatis hilang saat cutscene selesai.
- Belum ada sprite pixel Mama di paket aset, jadi sementara memakai sprite Lara dewasa (casual).
  Kalau sprite Mama sudah ada (nama file pola `<prefix>front 1.png` ... `left 3.png`),
  ganti `sprite_folder` dan `prefix` di node MamaNPC.
- Sesuai catatan skrip, mulai masa remaja Mama hanya muncul di kotak dialog.

## Bug UID ganda (penyebab Halaman kosong / petak umpet hilang)

Beberapa file lama punya UID yang sama dengan file yang dipakai game, jadi Godot kadang memuat file lama:
- `scripts/task_scripts/Stage_1_Park.gd` (salinan lama) = UID `Stage_1_Park.gd` -> Halaman jalan tanpa StoryDirector.
- `naratives/cutscenes/Cutscenes_List.gd` = UID autoload `CutscenesListKid` -> fungsi `play()` tidak ada.
- `scenes/tasks/Block_Macthing.tscn` + `scripts/task_scripts/Block_Macthing.gd` = UID minigame ayunan.
- `tasks/jemur_game/clothes.*`, `placeholder.*`, `tes.tscn` = UID versi di folder `thingies`.
Semua salinan lama itu dihapus. Saat membuka proyek, pakai folder baru (atau hapus folder `.godot`)
supaya cache UID lama ikut hilang.

## Yang belum ada

- Minigame "adventure ruang tamu" (Kid hari 3) dan make up (Kid hari 1) hanya berupa dialog.
- NPC Mama / Keisha belum ada sprite di ruangan.
- Progres belum tersimpan (save/load).
