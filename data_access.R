# ============================================================
# Kaggle 데이터셋 일괄 다운로드 스크립트 (순수 R, Python 불필요)
# 독자가 본인 Kaggle 계정으로 직접 데이터를 받아가는 방식
# ============================================================
#
#실행 전 getwd()로 위치를 꼭 확인하세요. 해당 폴더에 데이터가 저장됩니다.
#폴더 위치를 변경하려면 setwd()로 바꾸거나, R studio 우측하단 파일창에서 
#위치를 바꿀 수 있다.
# ============================================================
#install.packages("httr") #최초 한번만 httr 패키지 설치해야 함.
library(httr)

for (nm in c(
  "https://www.kaggle.com/datasets/sjleshrac/airlines-customer-satisfaction",
  "https://www.kaggle.com/datasets/mdraselsarker/amazon-fine-food-reviews",
  "https://www.kaggle.com/datasets/mrmars1010/iphone-customer-reviews-nlp",
  "https://www.kaggle.com/datasets/sakshigoyal7/credit-card-customers",
  "https://www.kaggle.com/datasets/marikastewart/employee-turnover",
  "https://www.kaggle.com/datasets/rahelederakhshande/marketing-ab",
  "https://www.kaggle.com/datasets/shashankshukla123123/marketing-campaign",
  "https://www.kaggle.com/datasets/pereprosov/retail-store-performance",
  "https://www.kaggle.com/datasets/matinmahmoudi/sales-and-satisfaction",
  "https://www.kaggle.com/datasets/thedevastator/tripadvisor-hotel-reviews",
  "https://www.kaggle.com/datasets/morveth/turkish-students-2025-yks-dataset-tyt-and-ayt",
  "https://www.kaggle.com/datasets/ujjwalchowdhury/walmartcleaned"
)) {
  message("  - ", nm)
}

# ===== 1. Kaggle API 인증 정보 =====

kaggle_username <- Sys.getenv("jkim2252666")
kaggle_key      <- Sys.getenv("KGAT_810bfc38663333b0b79d377543db3042")

if (kaggle_username == "jkim2252666" || kaggle_key == "KGAT_810bfc38663333b0b79d377543db3042") {
  stop(
    "Kaggle API 인증 정보가 없습니다.\n",
    "1) https://www.kaggle.com/settings 에서 API 토큰을 발급받으세요."
    
  )
}

# ===== 2. 데이터셋 다운로드 함수 =====
# 성공하면 dest_dir 경로를, 실패하면 NULL을 반환합니다 (실행을 멈추지 않음).
download_kaggle_dataset <- function(dataset_slug,
                                    dest_dir = file.path("kaggle_data", basename(dataset_slug)),
                                    force = FALSE) {
  
  if (dir.exists(dest_dir) && length(list.files(dest_dir)) > 0 && !force) {
    message("이미 다운로드됨: ", dest_dir, " (건너뜁니다. force=TRUE로 재다운로드 가능)")
    message("  -> 저장 위치: ", normalizePath(dest_dir))
    return(invisible(dest_dir))
  }
  
  result <- tryCatch({
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
    zip_path <- file.path(dest_dir, paste0(basename(dataset_slug), ".zip"))
    url <- paste0("https://www.kaggle.com/api/v1/datasets/download/", dataset_slug)
    
    message("다운로드 중: ", dataset_slug)
    res <- GET(
      url,
      authenticate(kaggle_username, kaggle_key),
      write_disk(zip_path, overwrite = TRUE)
    )
    
    if (status_code(res) != 200) {
      stop("다운로드 실패 (status ", status_code(res), "): ", dataset_slug,
           " -- 해당 데이터셋 페이지에서 'I Understand and Accept' 규칙 동의가 ",
           "필요할 수 있습니다.")
    }
    
    unzip(zip_path, exdir = dest_dir)
    file.remove(zip_path)
    
    message("완료: ", dest_dir)
    message("  -> 저장 위치: ", normalizePath(dest_dir))
    dest_dir
  }, error = function(e) {
    message("[실패] ", dataset_slug, " -- ", conditionMessage(e))
    NULL
  })
  
  invisible(result)
}

# ===== 3. 책에서 사용하는 데이터셋 목록 (slug + 라이선스) =====
datasets <- list(
  list(name = "Airlines Customer Satisfaction",
       slug = "sjleshrac/airlines-customer-satisfaction",
       license = "CC0 Public Domain"),
  list(name = "Amazon Fine Food Reviews",
       slug = "mdraselsarker/amazon-fine-food-reviews",
       license = "Apache 2.0"),
  list(name = "Apple iPhone Customer Reviews",
       slug = "mrmars1010/iphone-customer-reviews-nlp",
       license = "CC0 Public Domain"),
  list(name = "Credit Card Customers",
       slug = "sakshigoyal7/credit-card-customers",
       license = "CC0 Public Domain"),
  list(name = "Employee Turnover",
       slug = "marikastewart/employee-turnover",
       license = "Public Domain"),
  list(name = "Marketing_AB",
       slug = "rahelederakhshande/marketing-ab",
       license = "ODbL 1.0"),
  list(name = "Marketing Campaign",
       slug = "shashankshukla123123/marketing-campaign",
       license = "CC0 Public Domain"),
  list(name = "Retail Store Performance",
       slug = "pereprosov/retail-store-performance",
       license = "Apache 2.0"),
  list(name = "Sales and Satisfaction",
       slug = "matinmahmoudi/sales-and-satisfaction",
       license = "CC BY-SA 4.0"),
  list(name = "TripAdvisor Hotel Reviews",
       slug = "thedevastator/tripadvisor-hotel-reviews",
       license = "CC0 Public Domain"),
  list(name = "Turkish Students 2025 YKS Dataset",
       slug = "morveth/turkish-students-2025-yks-dataset-tyt-and-ayt",
       license = "MIT"),
  list(name = "Walmart Cleaned Data",
       slug = "ujjwalchowdhury/walmartcleaned",
       license = "CC0 Public Domain")
)

# ===== 4. 전체 다운로드 실행 (하나 실패해도 나머지는 계속 진행) =====
download_paths <- lapply(datasets, function(ds) download_kaggle_dataset(ds$slug))
results <- !sapply(download_paths, is.null)
names(results) <- sapply(datasets, function(ds) ds$name)

# ===== 5. 다운로드한 데이터셋의 라이선스 요약표 출력/저장 =====
license_table <- do.call(rbind, Map(function(ds, path) {
  data.frame(
    dataset = ds$name,
    kaggle_slug = ds$slug,
    license = ds$license,
    source_url = paste0("https://www.kaggle.com/datasets/", ds$slug),
    downloaded = !is.null(path),
    stringsAsFactors = FALSE
  )
}, datasets, download_paths))

print(license_table)
dir.create("kaggle_data", showWarnings = FALSE)
write.csv(license_table, "kaggle_data/DATA_LICENSES.csv", row.names = FALSE)

# ===== 6. 결과 요약 =====
message("")
message(strrep("=", 60))
message("다운로드 완료: ", sum(results), " / ", length(results))
message("데이터는 아래 경로에 각각 저장되었습니다 (kaggle_data/DATA_LICENSES.csv 에서도 확인 가능):")
