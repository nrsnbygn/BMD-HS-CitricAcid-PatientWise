# Öğrenci için çalıştırma talimatı

Bu repo tezdeki yöntemin sonuçlarını **hasta bağımsız ve veri sızıntısı olmayacak şekilde** yeniden test etmek içindir. Tez metnini şimdilik değiştirmeyin; önce bu deneyi tamamlayıp sonuç dosyalarını danışmana gönderin.

## 1. Repoyu indirin

GitHub'dan `Code > Download ZIP` ile indirin ve ZIP'i açın.

## 2. Tezde kullandığınız 2120 öznitelikli matrisi hazırlayın

Tezdeki mevcut kodunuzla ürettiğiniz öznitelik matrisini `data/features_2120.mat` olarak kaydedin. Dosyada tam olarak şu üç değişken bulunmalıdır:

```matlab
X          % 8716 x 2120 öznitelik matrisi (veya gerçekten kullanılan segment sayısı)
y          % her segmentin N/AS/AR/MR/MS/MD etiketi
subjectID  % her segmentin ait olduğu 109 hastadan hangisi olduğunu gösteren kimlik
save('data/features_2120.mat','X','y','subjectID','-v7.3')
```

**Kritik:** Aynı hastanın 8 farklı kaydı ve bu kayıtlardan çıkan bütün 2 saniyelik segmentler aynı `subjectID` değerini taşımalıdır. Kayıt veya segment başına yeni hasta numarası üretmeyin.

## 3. MATLAB'da çalıştırın

MATLAB Current Folder'ı repo klasörü yapın:

```matlab
setup
smoke_test
run_all
```

## 4. Danışmana gönderilecek dosyalar

Çalışma bittikten sonra `results` klasörünü ZIP yapıp gönderin. Özellikle şu dosyalar gereklidir:

- `SUMMARY.csv`
- `LEAKAGE_AUDIT.csv`
- `patientwise_fold_assignment.csv`
- `baseline_fold_metrics.csv`
- `proposed_fold_metrics.csv`
- `baseline_predictions.csv`
- `proposed_predictions.csv`
- tüm `*_nca.mat` dosyaları

`LEAKAGE_AUDIT.csv` içindeki bütün `OverlapSubjects` değerleri **0** olmalıdır. Aksi durumda sonuçlar kullanılmayacaktır.

## 5. Sonuçların anlamı

`baseline_stats`: tezdeki istatistiksel özelliklerin hasta bağımsız sonucu.

`proposed_cap_stats`: tezdeki özgün Citric Acid Pattern + istatistiksel özelliklerin hasta bağımsız sonucu.

İki deney aynı hasta fold'larını kullanır. Böylece Citric Acid Pattern'in gerçekten ek katkı sağlayıp sağlamadığı doğrudan karşılaştırılabilir.

## Önemli

Eski tezdeki yaklaşık doğruluk değerlerini yeniden elde etmeye çalışmak için hasta ayrımını bozmayın. Yeni değerlendirmede doğruluğun düşmesi tek başına kod hatası anlamına gelmez. Amaç, daha önce görülmemiş hastalarda geçerli performansı ölçmektir.
