extends Node
# Bank soal (dari Bank_Soal.pdf).
# answer = nomor pilihan yang benar, dihitung dari 0 (A = 0, B = 1, C = 2, D = 3, E = 4)

const QUESTIONS: Array = [
	{
		"question": "Choose the closest meaning of the word \"inevitable\".",
		"options": ["Avoidable", "Uncertain", "Unavoidable", "Temporary", "Unnecessary"],
		"answer": 2,
	},
	{
		"question": "Sebuah benda bergerak dengan kecepatan awal 5 m/s dan percepatan konstan 2 m/s² selama 4 detik. Jarak yang ditempuh benda adalah...",
		"options": ["20 m", "24 m", "28 m", "32 m", "36 m"],
		"answer": 4,
	},
	{
		"question": "Batang homogen panjang 4 m dan berat 200 N diletakkan horizontal, ditumpu tepat di titik tengahnya. Torsi akibat berat batang terhadap titik tumpu adalah...",
		"options": ["0 Nm", "100 Nm", "200 Nm", "400 Nm", "800 Nm"],
		"answer": 0,
	},
	{
		"question": "Jika f(x) = x³ − 5x² + 4x, maka nilai f'(2) adalah...",
		"options": ["-8", "-4", "0", "4", "8"],
		"answer": 1,
	},
	{
		"question": "Menurut Hukum Kepler II, ketika planet berada lebih dekat dengan bintangnya, planet akan...",
		"options": [
			"Bergerak lebih lambat karena jaraknya makin dekat",
			"Bergerak lebih cepat (menyapu luas sama dalam waktu sama)",
			"Memiliki massa yang lebih besar",
			"Berhenti sesaat sebelum menjauhi bintang",
			"Mengalami perubahan periode revolusi",
		],
		"answer": 1,
	},
	{
		"question": "Kalimat yang menggunakan konjungsi kausalitas adalah...",
		"options": [
			"Ia belajar dengan tekun agar memperoleh hasil baik.",
			"Ia tetap berangkat meskipun hujan turun.",
			"Ia tidak menghadiri pertemuan karena sedang sakit.",
			"Ia membaca buku kemudian menulis rangkuman.",
			"Ia memilih matematika daripada fisika.",
		],
		"answer": 2,
	},
	{
		"question": "Sebuah dadu dilempar satu kali. Peluang munculnya bilangan prima adalah...",
		"options": ["1/6", "1/3", "1/2", "2/3", "5/6"],
		"answer": 2,
	},
	{
		"question": "Jika sin θ = 3/5 dan θ berada di kuadran I, nilai cos θ adalah...",
		"options": ["1/5", "2/5", "3/5", "4/5", "5/3"],
		"answer": 3,
	},
	{
		"question": "Perjalanan Odysseus: tahap pertama 120 km, setiap tahap berikutnya bertambah 30 km. Total jarak setelah 5 tahap adalah...",
		"options": ["720 km", "780 km", "810 km", "840 km", "900 km"],
		"answer": 4,
	},
	{
		"question": "Wahana antariksa bergerak dengan kecepatan konstan 30 km/s selama 5 hari. Jarak yang ditempuh adalah...",
		"options": ["6.480 km", "64.800 km", "648.000 km", "12.960.000 km", "12.960.000.000 km"],
		"answer": 3,
	},
]
