use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::io::Read;
use std::path::{Path, PathBuf};

#[derive(Serialize, Deserialize, Debug)]
pub struct CleanHistory {
    pub file_name: String,
    pub original_size: u64,
    pub cleaned_size: u64,
    pub timestamp: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct EngineState {
    pub status: String,
    pub mode: String,
    pub total_cleaned: usize,
    pub history: Vec<CleanHistory>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct StatusOutput {
    pub text: String,
    pub tooltip: String,
    pub class: String,
}

fn get_state_file() -> PathBuf {
    let base = env::var("XDG_STATE_HOME")
        .unwrap_or_else(|_| format!("{}/.local/state", env::var("HOME").unwrap_or_default()));
    let dir = Path::new(&base).join("omarchy/opsec-cleaner");
    let _ = fs::create_dir_all(&dir);
    dir.join("state.json")
}

fn load_state() -> EngineState {
    let sf = get_state_file();
    if let Ok(content) = fs::read_to_string(&sf) {
        if let Ok(st) = serde_json::from_str(&content) {
            return st;
        }
    }
    EngineState {
        status: "READY".to_string(),
        mode: "LOSSLESS METADATA STRIP".to_string(),
        total_cleaned: 0,
        history: Vec::new(),
    }
}

fn save_state(state: &EngineState) {
    let sf = get_state_file();
    if let Ok(json) = serde_json::to_string_pretty(state) {
        let _ = fs::write(sf, json);
    }
}

// Lossless JPEG EXIF strip: preserves SOI (0xFFD8) and removes APP1 (0xFFE1) to APP15 markers, retaining image frames
fn strip_jpeg_exif(data: &[u8]) -> Option<Vec<u8>> {
    if data.len() < 4 || data[0] != 0xFF || data[1] != 0xD8 {
        return None;
    }
    let mut out = Vec::with_capacity(data.len());
    out.push(0xFF);
    out.push(0xD8);

    let mut idx = 2;
    while idx < data.len() {
        if data[idx] != 0xFF {
            out.extend_from_slice(&data[idx..]);
            break;
        }
        while idx < data.len() && data[idx] == 0xFF {
            idx += 1;
        }
        if idx >= data.len() {
            break;
        }
        let marker = data[idx];
        idx += 1;

        if marker == 0xD9 { // EOI
            out.push(0xFF);
            out.push(0xD9);
            break;
        }
        if marker == 0xDA { // SOS (Start of Scan - image data begins)
            out.push(0xFF);
            out.push(0xDA);
            out.extend_from_slice(&data[idx..]);
            break;
        }

        if idx + 2 > data.len() {
            break;
        }
        let len = ((data[idx] as usize) << 8) | (data[idx + 1] as usize);
        if idx + len > data.len() {
            break;
        }

        // APP1 (EXIF), APP2 (FlashPix/ICC), APP13 (Photoshop IPTC), APP14 (Adobe), COM (Comment)
        let is_meta = (marker >= 0xE1 && marker <= 0xEF) || marker == 0xFE;
        if !is_meta {
            out.push(0xFF);
            out.push(marker);
            out.extend_from_slice(&data[idx..idx + len]);
        }
        idx += len;
    }
    Some(out)
}

// Lossless PNG metadata strip: removes tEXt, zTXt, iTXt, eXIf chunks
fn strip_png_metadata(data: &[u8]) -> Option<Vec<u8>> {
    let png_header = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if data.len() < 8 || &data[..8] != png_header {
        return None;
    }
    let mut out = Vec::with_capacity(data.len());
    out.extend_from_slice(&png_header);

    let mut idx = 8;
    while idx + 12 <= data.len() {
        let length = ((data[idx] as usize) << 24)
            | ((data[idx + 1] as usize) << 16)
            | ((data[idx + 2] as usize) << 8)
            | (data[idx + 3] as usize);
        let chunk_type = &data[idx + 4..idx + 8];
        let total_chunk_len = 12 + length;
        if idx + total_chunk_len > data.len() {
            out.extend_from_slice(&data[idx..]);
            break;
        }

        let is_meta = match chunk_type {
            b"tEXt" | b"zTXt" | b"iTXt" | b"eXIf" | b"tIME" => true,
            _ => false,
        };

        if !is_meta {
            out.extend_from_slice(&data[idx..idx + total_chunk_len]);
        }
        idx += total_chunk_len;
    }
    Some(out)
}

fn clean_file(path: &Path) -> Result<(u64, u64), String> {
    if !path.is_file() {
        return Err("Not a file".to_string());
    }
    let mut data = Vec::new();
    let mut f = fs::File::open(path).map_err(|e| e.to_string())?;
    f.read_to_end(&mut data).map_err(|e| e.to_string())?;
    let orig_len = data.len() as u64;

    let cleaned = if let Some(j) = strip_jpeg_exif(&data) {
        j
    } else if let Some(p) = strip_png_metadata(&data) {
        p
    } else {
        return Err("Unsupported format or not an image".to_string());
    };

    let new_len = cleaned.len() as u64;
    fs::write(path, cleaned).map_err(|e| e.to_string())?;
    Ok((orig_len, new_len))
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut state = load_state();

    if args.iter().any(|a| a == "--status") {
        let text = format!("OPSEC: READY ({} CLEANED)", state.total_cleaned);
        let tooltip = format!(
            "OpSec Cleaner - Metadata Scrubber\nStatus: READY\nEngine: Native Rust\nTotal Cleaned: {}",
            state.total_cleaned
        );
        let out = StatusOutput {
            text,
            tooltip,
            class: "normal".to_string(),
        };
        println!("{}", serde_json::to_string(&out).unwrap());
        return;
    }

    if args.iter().any(|a| a == "--json") {
        println!("{}", serde_json::to_string_pretty(&state).unwrap());
        return;
    }

    if let Some(pos) = args.iter().position(|a| a == "--clean-dir") {
        let target_dir = if pos + 1 < args.len() && !args[pos + 1].starts_with("--") {
            PathBuf::from(&args[pos + 1])
        } else {
            let home = env::var("HOME").unwrap_or_else(|_| ".".to_string());
            PathBuf::from(home).join("Downloads")
        };

        if target_dir.is_dir() {
            if let Ok(entries) = fs::read_dir(&target_dir) {
                for entry in entries.flatten() {
                    let p = entry.path();
                    if p.is_file() {
                        if let Some(ext) = p.extension().and_then(|s| s.to_str()) {
                            let ext_lower = ext.to_lowercase();
                            if ext_lower == "jpg" || ext_lower == "jpeg" || ext_lower == "png" {
                                if let Ok((orig, new_sz)) = clean_file(&p) {
                                    state.total_cleaned += 1;
                                    state.history.insert(0, CleanHistory {
                                        file_name: p.file_name().unwrap_or_default().to_string_lossy().to_string(),
                                        original_size: orig,
                                        cleaned_size: new_sz,
                                        timestamp: "Just now".to_string(),
                                    });
                                }
                            }
                        }
                    }
                }
                state.history.truncate(10);
                save_state(&state);
            }
        }
        return;
    }

    if let Some(pos) = args.iter().position(|a| a == "--clean") {
        if pos + 1 < args.len() {
            let target = Path::new(&args[pos + 1]);
            match clean_file(target) {
                Ok((orig, new_sz)) => {
                    println!("SUCCESS: Cleaned {} ({} -> {} bytes)", target.display(), orig, new_sz);
                    state.total_cleaned += 1;
                    state.history.insert(0, CleanHistory {
                        file_name: target.file_name().unwrap_or_default().to_string_lossy().to_string(),
                        original_size: orig,
                        cleaned_size: new_sz,
                        timestamp: "Just now".to_string(),
                    });
                    state.history.truncate(10);
                    save_state(&state);
                }
                Err(e) => {
                    eprintln!("ERROR: Could not clean {}: {}", target.display(), e);
                    std::process::exit(1);
                }
            }
            return;
        }
    }

    // Default summary
    println!("OPSEC METADATA CLEANER - NATIVE RUST ENGINE");
    println!("Status: READY | Total Cleaned: {}", state.total_cleaned);
    println!("Supported Formats: JPEG (EXIF, APP1-APP15), PNG (tEXt, zTXt, iTXt, eXIf)");
}
