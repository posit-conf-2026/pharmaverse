# Generates the three "End-to-End with Barb!" journey images used in
# slides/01-intro/index.qmd. Run from repo root:  Rscript slides/01-intro/scripts/make-barb-images.R
#
# Subject followed across the pipeline: 01-701-1015 ("Barb", Placebo arm).
# Tables are drawn with grid (no browser needed) at high DPI for crisp text.

suppressMessages({
  library(dplyr)
  library(grid)
  library(ragg)
  library(magick)
  library(pharmaversesdtm)
  library(pharmaverseadam)
})

SUBJ    <- "01-701-1015"
outdir  <- "slides/01-intro"
barb_png <- file.path(outdir, "barb-transparent.png")

## ---- palette -------------------------------------------------------------
navy   <- "#134a7c"
navy_d <- "#0d3357"
zebra  <- "#eef4fb"
amber  <- "#fce9b8"
amber_b<- "#e08a1e"
ink    <- "#1a1a1a"
grey   <- "#5a6b7b"

## ---- grid table drawer ---------------------------------------------------
# Draws a table into the current viewport region [x0,x1]x[y0,y1] (npc units).
draw_table <- function(header, colnames, rows, widths,
                       x0, x1, y0, y1,
                       hl_rows = integer(0),
                       header_fill = navy,
                       title_cex = 1.25, head_cex = 0.95, body_cex = 0.95) {
  stopifnot(length(colnames) == length(widths))
  widths <- widths / sum(widths)
  nrow_b <- length(rows)

  # vertical layout: title band, colname band, then body rows
  title_h <- 0.16
  head_h  <- 0.11
  body_top <- y1 - (y1 - y0) * (title_h + head_h)
  row_h <- (body_top - y0) / max(nrow_b, 1)

  # outer border
  grid.rect(x = unit((x0 + x1) / 2, "npc"), y = unit((y0 + y1) / 2, "npc"),
            width = unit(x1 - x0, "npc"), height = unit(y1 - y0, "npc"),
            gp = gpar(col = navy_d, lwd = 3, fill = NA))

  # title band
  grid.rect(x = unit((x0 + x1) / 2, "npc"), y = unit(y1 - (y1 - y0) * title_h / 2, "npc"),
            width = unit(x1 - x0, "npc"), height = unit((y1 - y0) * title_h, "npc"),
            gp = gpar(col = NA, fill = header_fill))
  grid.text(header, x = unit(x0 + 0.02, "npc"),
            y = unit(y1 - (y1 - y0) * title_h / 2, "npc"),
            just = "left", gp = gpar(col = "white", fontface = "bold", cex = title_cex))

  # column x-centers from widths
  span <- x1 - x0
  edges <- x0 + cumsum(c(0, widths)) * span
  centers <- (head(edges, -1) + tail(edges, -1)) / 2

  head_y <- body_top + head_h * (y1 - y0) / 2 + (title_h * 0) # center of colname band
  head_cy <- body_top + (y1 - y0) * head_h / 2
  # colname band background
  grid.rect(x = unit((x0 + x1) / 2, "npc"), y = unit(head_cy, "npc"),
            width = unit(x1 - x0, "npc"), height = unit((y1 - y0) * head_h, "npc"),
            gp = gpar(col = NA, fill = zebra))
  for (j in seq_along(colnames)) {
    grid.text(colnames[j], x = unit(centers[j], "npc"), y = unit(head_cy, "npc"),
              just = "center", gp = gpar(col = navy, fontface = "bold", cex = head_cex))
  }

  # body rows
  for (i in seq_len(nrow_b)) {
    ry_top <- body_top - (i - 1) * row_h
    ry_c   <- ry_top - row_h / 2
    fill <- if (i %in% hl_rows) amber else if (i %% 2 == 0) zebra else "white"
    grid.rect(x = unit((x0 + x1) / 2, "npc"), y = unit(ry_c, "npc"),
              width = unit(x1 - x0, "npc"), height = unit(row_h, "npc"),
              gp = gpar(col = "#d7dee6", lwd = 0.8, fill = fill))
    if (i %in% hl_rows) {
      grid.rect(x = unit((x0 + x1) / 2, "npc"), y = unit(ry_c, "npc"),
                width = unit(x1 - x0, "npc"), height = unit(row_h, "npc"),
                gp = gpar(col = amber_b, lwd = 2, fill = NA))
    }
    vals <- rows[[i]]
    for (j in seq_along(vals)) {
      grid.text(vals[j], x = unit(centers[j], "npc"), y = unit(ry_c, "npc"),
                just = "center", gp = gpar(col = ink, cex = body_cex))
    }
  }
}

place_barb <- function(x, y, w) {
  if (!file.exists(barb_png)) return(invisible())
  img <- magick::image_read(barb_png)
  ras <- as.raster(img)
  grid.raster(ras, x = unit(x, "npc"), y = unit(y, "npc"),
              width = unit(w, "npc"), just = "center")
}

## ---- annotation helpers (aCRF style) ------------------------------------
# blue SDTM variable callout tag
var_tag <- function(label, x, y, cex = 0.8) {
  w <- unit(0.9, "strwidth", label) + unit(6, "mm")
  grid.roundrect(x = unit(x, "npc"), y = unit(y, "npc"),
                 width = w, height = unit(6.5, "mm"), r = unit(1.2, "mm"),
                 gp = gpar(col = NA, fill = navy))
  grid.text(label, x = unit(x, "npc"), y = unit(y, "npc"),
            gp = gpar(col = "white", fontface = "bold", cex = cex))
}
# amber "Variable Domain / Name" style note
note_tag <- function(label, x, y, cex = 0.62) {
  w <- unit(0.9, "strwidth", label) + unit(5, "mm")
  grid.roundrect(x = unit(x, "npc"), y = unit(y, "npc"),
                 width = w, height = unit(5.5, "mm"), r = unit(1, "mm"),
                 gp = gpar(col = amber_b, fill = amber))
  grid.text(label, x = unit(x, "npc"), y = unit(y, "npc"),
            gp = gpar(col = "#5b4300", cex = cex))
}
# a form field:  "Label: [ value ]"
form_field <- function(label, value, x_lab, y, box_x0 = NA, box_x1 = NA,
                       lab_cex = 0.92, val_cex = 0.92, val_col = ink,
                       val_face = "plain") {
  grid.text(label, x = unit(x_lab, "npc"), y = unit(y, "npc"),
            just = "left", gp = gpar(col = ink, cex = lab_cex))
  if (!is.na(box_x0)) {
    grid.roundrect(x = unit((box_x0 + box_x1) / 2, "npc"), y = unit(y, "npc"),
                   width = unit(box_x1 - box_x0, "npc"), height = unit(7, "mm"),
                   r = unit(0.8, "mm"), gp = gpar(col = "#9aa7b4", fill = "white", lwd = 1.2))
    grid.text(value, x = unit(box_x0 + 0.012, "npc"), y = unit(y, "npc"),
              just = "left", gp = gpar(col = val_col, cex = val_cex, fontface = val_face))
  }
}

## ---- data ----------------------------------------------------------------
data("dm", package = "pharmaversesdtm")
dm1 <- dm %>% filter(USUBJID == SUBJ) %>%
  select(USUBJID, SEX, RACE, ETHNIC, ARM, AGE) %>% slice(1)

data("advs", package = "pharmaverseadam")
advs1 <- advs %>%
  filter(USUBJID == SUBJ, PARAMCD == "DIABP", !is.na(BASE), !is.na(CHG)) %>%
  distinct(AVAL, BASE, CHG, .keep_all = TRUE) %>%
  select(PARAMCD, AVISIT, AVAL, BASE, CHG) %>%
  head(4)

## =========================================================================
## 1. DATA COLLECTION  -> barb-sdtm.png  (annotated eCRF / aCRF)
## =========================================================================
ragg::agg_png(file.path(outdir, "barb-sdtm.png"),
              width = 1900, height = 950, units = "px", background = "white", res = 220)
grid.newpage()

# form panel background
grid.roundrect(x = unit(0.41, "npc"), y = unit(0.52, "npc"),
               width = unit(0.76, "npc"), height = unit(0.82, "npc"),
               r = unit(3, "mm"), gp = gpar(col = navy_d, lwd = 3, fill = "#fbfcfe"))

# form title
grid.text("Demographics  (eCRF)", x = unit(0.06, "npc"), y = unit(0.86, "npc"),
          just = "left", gp = gpar(col = navy, fontface = "bold", cex = 1.15))
note_tag("DM = Demographics domain", x = 0.66, y = 0.86, cex = 0.62)

# fields
form_field("Date of Birth:", "__ / ___ / ____", 0.06, 0.70,
           box_x0 = 0.26, box_x1 = 0.50)
var_tag("BRTHDTC", x = 0.585, y = 0.70)

form_field("Race:", "CAT  \u2714", 0.06, 0.555,
           box_x0 = 0.16, box_x1 = 0.50, val_col = amber_b, val_face = "bold")
var_tag("RACE", x = 0.585, y = 0.555)

form_field("Sex:    Male  \u25cb      Female  \u2611", "", 0.06, 0.41)
var_tag("SEX", x = 0.585, y = 0.41)

form_field("Ethnicity:", as.character(dm1$ETHNIC), 0.06, 0.265,
           box_x0 = 0.22, box_x1 = 0.50, val_cex = 0.7)
var_tag("ETHNIC", x = 0.585, y = 0.265)
note_tag("Variable Name", x = 0.70, y = 0.265, cex = 0.62)

# Barb (she filled in her own race)
place_barb(0.87, 0.5, 0.2)
invisible(dev.off())

## =========================================================================
## 2. DATA AGGREGATION -> barb-adam.png  (ADVS derivation: CHG = AVAL - BASE)
## =========================================================================
ragg::agg_png(file.path(outdir, "barb-adam.png"),
              width = 2000, height = 850, units = "px", background = "white", res = 220)
grid.newpage()

# ADaM ADVS table (simple, obvious derivation)
adam_cols <- c("PARAMCD", "AVISIT", "BASE", "AVAL", "CHG")
adam_rows <- lapply(seq_len(nrow(advs1)), function(i)
  as.character(c(advs1$PARAMCD[i], advs1$AVISIT[i],
                 advs1$BASE[i], advs1$AVAL[i], advs1$CHG[i])))
draw_table(
  header  = "ADaM \u2022 ADVS   (analysis-ready)",
  colnames = adam_cols,
  rows    = adam_rows,
  widths  = c(1.2, 1.2, 0.9, 0.9, 0.9),
  x0 = 0.05, x1 = 0.72, y0 = 0.30, y1 = 0.92,
  hl_rows = seq_len(nrow(advs1)),
  head_cex = 0.82, body_cex = 0.9
)

# derivation callout
grid.roundrect(x = unit(0.385, "npc"), y = unit(0.14, "npc"),
               width = unit(0.5, "npc"), height = unit(0.12, "npc"),
               r = unit(2, "mm"), gp = gpar(col = amber_b, fill = amber, lwd = 1.5))
grid.text("Derived:   CHG  =  AVAL  \u2212  BASE",
          x = unit(0.385, "npc"), y = unit(0.14, "npc"),
          gp = gpar(col = "#5b4300", fontface = "bold", cex = 0.95))

place_barb(0.88, 0.52, 0.16)
invisible(dev.off())

cat("Wrote barb-sdtm.png (aCRF) and barb-adam.png (ADVS derivation)\n")
