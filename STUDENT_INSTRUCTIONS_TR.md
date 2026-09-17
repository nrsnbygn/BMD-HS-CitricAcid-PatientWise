# Öğrenci için çalıştırma talimatı

Bu repo tezdeki yöntemi **hasta bağımsız ve veri sızıntısı olmayacak şekilde** yeniden test eder. Tez metnini şimdilik değiştirmeyin; önce deneyi tamamlayıp sonuç klasörünü danışmana gönderin.

## 1. Repoyu indirin
GitHub'dan `Code > Download ZIP` ile indirin ve ZIP'i açın.

## 2. Tezde kullandığınız ORİJİNAL 2120 öznitelikli matrisi hazırlayın
Tezde sonuçları üretirken kullandığınız mevcut öznitelik matrisini `data/features_2120.mat` olarak kaydedin:

```matlab
X          % segment x 2120: tezde kullanılan orijinal özellikler
y          % her segmentin N/AS/AR/MR/MS/MD etiketi
subjectID  % segmentin ait olduğu gerçek hasta kimliği
save('data/features_2120.mat','X','y','subjectID','-v7.3')
```

**Kritik:** Aynı hastanın 8 kaydı ve bunlardan oluşan bütün 2 saniyelik segmentler aynı `subjectID` değerini taşımalıdır. Kayıt veya segment başına yeni hasta numarası üretmeyin. Kod 109'dan farklı hasta sayısı görürse uyarı verecektir; bir hastada birden fazla tez sınıf etiketi görürse çalışmayı durduracaktır.

## 3. MATLAB'da çalıştırın
Current Folder repo klasörü iken:

```matlab
setup
smoke_test
run_all
```

`smoke_test` başarılı olmadan ana deneyi kullanmayın. Başarılı test mesajında CAP=384, patient overlap=0, train-only NCA ve classifier kontrolü görülür.

## 4. Çalıştırılan üç deney
Aynı patient-wise fold'lar üzerinde:

- `baseline_stats`: yalnız istatistiksel özellikler
- `cap_only`: yalnız Citric Acid Pattern özellikleri (ablation)
- `proposed_cap_stats`: tezdeki Citric Acid Pattern + istatistiksel özellikler

NCA her fold'da yalnız eğitim hastalarında öğrenilir. Test hastalarının etiketleri NCA, ölçekleme veya model eğitiminde kullanılmaz.

## 5. Danışmana gönderilecekler
Çalışma bittikten sonra **results klasörünün tamamını ZIP yapıp gönderin**. Özellikle:

- `SUMMARY.csv`
- `LEAKAGE_AUDIT.csv`
- `patientwise_fold_assignment.csv`
- `subject_level_folds.csv`
- `baseline_*`
- `cap_only_*`
- `proposed_*`
- tüm `*_nca.mat` dosyaları

`LEAKAGE_AUDIT.csv` içindeki bütün `OverlapSubjects` değerleri **0** olmalıdır. Aksi durumda sonuçlar kullanılmayacaktır.

## Önemli
Eski tez doğruluklarını yakalamak amacıyla hasta ayrımını veya NCA sırasını değiştirmeyin. Hasta-bağımsız sonuçların daha düşük olması tek başına kod hatası değildir. `SUMMARY.csv` içindeki Accuracy yanında özellikle BalancedAccuracy ve MacroF1 değerlerini de raporlayın.
