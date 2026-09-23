# Öğrenci için çalıştırma talimatı — dengeli deney

Bu sürüm, önceki leakage-safe sonuçlarda modelin MD sınıfına yönelmesini incelemek için güncellendi.

## Yapılacak işlem

Repoyu yeniden indirin/güncelleyin. Daha önce hazırladığınız **aynı** `data/features_2120.mat` dosyasını kullanın. MATLAB'da:

```matlab
setup
smoke_test
run_all
```

Kod yine aynı patient-wise fold'ları kullanır. NCA ve standardizasyon yalnız training verisinde öğrenilir. Yeni olarak **random undersampling yalnız training fold içinde** uygulanır. Test/validation hastaları kesinlikle dengelenmez veya değiştirilmez.

Üç deney aynı fold'larda tekrar çalışır:

- `balanced_baseline_stats`: yalnız istatistiksel özellikler
- `balanced_cap_only`: yalnız Citric Acid Pattern
- `balanced_proposed_cap_stats`: Citric Acid Pattern + istatistiksel özellikler

Çalışma bitince **results klasörünün tamamını ZIP yapıp gönderin**. Özellikle `BALANCED_SUMMARY.csv`, `LEAKAGE_AUDIT.csv`, üç confusion matrix, per-class sonuçlar ve fold metrics dosyaları gerekli.

`LEAKAGE_AUDIT.csv` içindeki bütün `OverlapSubjects` değerleri 0 olmalıdır.

**Not:** Amaç accuracy'yi yapay biçimde yükseltmek değildir. MD çoğunluk sınıfına çökme davranışının training tarafındaki sınıf dengesizliğinden ne ölçüde kaynaklandığını ve CAP'ın diğer sınıfları ayırt etmeye katkısını görmek istiyoruz. Test dağılımına dokunmayın.
