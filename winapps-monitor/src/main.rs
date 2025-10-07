use anyhow::Result;
use chrono::Local;
use std::collections::HashMap;
use std::sync::{Mutex, MutexGuard, OnceLock};
use std::ffi::OsString;
use std::os::windows::ffi::OsStringExt;
use std::cell::Cell;
use tray_icon::{TrayIconBuilder, Icon};
use windows::{
    core::BOOL,
    Win32::{
        Foundation::{HWND, LPARAM},
        Graphics::Dwm::{DwmGetWindowAttribute, DWMWA_CLOAKED},
        UI::{
            Accessibility::{SetWinEventHook, UnhookWinEvent, HWINEVENTHOOK},
            WindowsAndMessaging::{
                EnumWindows, GetAncestor, GetLastActivePopup, GetWindowLongPtrW,
                GetWindowTextLengthW, GetWindowTextW, GetWindowThreadProcessId, IsWindowVisible,
                GetClassNameW, EnumChildWindows, GetMessageW, TranslateMessage, DispatchMessageW,
                GA_ROOTOWNER, GWL_EXSTYLE, WS_EX_TOOLWINDOW, WS_EX_APPWINDOW, EVENT_OBJECT_CREATE,
                EVENT_OBJECT_DESTROY, EVENT_OBJECT_SHOW, EVENT_OBJECT_HIDE, EVENT_OBJECT_CLOAKED,
                EVENT_OBJECT_UNCLOAKED, OBJID_WINDOW, EVENT_OBJECT_NAMECHANGE,
                WINEVENT_OUTOFCONTEXT, WINEVENT_SKIPOWNPROCESS, OBJECT_IDENTIFIER, MSG
            }
        }
    }
};

type WindowKey = isize;
#[derive(Clone, Debug)]
struct WindowEntry {
    pid: u32,
    title: String,
}
#[repr(C)]
struct UwpPidSearch<'a> {
    frame_pid: u32,
    found_pid: &'a Cell<u32>,
}
static WINDOWS: OnceLock<Mutex<HashMap<WindowKey, WindowEntry>>> = OnceLock::new();

/// Name: windows_map
/// Purpose: Lazy global initialiser for 'WINDOWS'.
fn windows_map() -> &'static Mutex<HashMap<WindowKey, WindowEntry>> {
    WINDOWS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Name: on_win_event
/// Purpose: Callback function registered via SetWinEventHook.
/// Events:
/// - WINDOW APPEARED:        EVENT_OBJECT_CREATE, EVENT_OBJECT_SHOW, EVENT_OBJECT_UNCLOAKED
/// - WINDOW DISAPPEARED:     EVENT_OBJECT_HIDE, EVENT_OBJECT_DESTROY, EVENT_OBJECT_CLOAKED
/// - WINDOW NAME CHANGED:    EVENT_OBJECT_NAMECHANGE
extern "system" fn on_win_event (
    _hook: HWINEVENTHOOK,
    event: u32,
    hwnd: HWND,
    id_object: i32,
    _id_child: i32,
    _evt_thread: u32,
    _evt_time: u32
) {
    // Debugging
    //println!("[evt {event:#x}] hwnd={:?} id_object={}", hwnd, id_object);
    //return;

    // Ignore non-window events
    if OBJECT_IDENTIFIER(id_object) != OBJID_WINDOW {
        return;
    }

    // Ignore events without an associated window to inspect
    if hwnd == HWND::default() {
        return;
    }

    // Check if a window appeared or disappeared
    if matches!(event, EVENT_OBJECT_CREATE | EVENT_OBJECT_SHOW | EVENT_OBJECT_UNCLOAKED) {
        // Check the new window is a user-facing main/top-level application window
        if !is_candidate_window(hwnd) {
            return;
        }

        /*
        // Require non-empty title
        unsafe {
            if GetWindowTextLengthW(hwnd) == 0 {
                return;
            }
        }
        */

        // Identify the process ID
        let pid: u32 =
            if is_application_frame_window(hwnd) {
                // UWP
                uwp_pid(hwnd)
            } else {
                // Win32
                let mut p: u32 = 0u32;
                unsafe {
                    GetWindowThreadProcessId(hwnd, Some(&mut p));
                }
                p
            };

        // Grab the current title (can empty on window creation)
        let title: String = window_title(hwnd);

        // Add window
        add_window(hwnd.0 as isize, pid, title);
        debug_dump_windows();
    } else if matches!(event, EVENT_OBJECT_NAMECHANGE) {
        // Store the new window title
        let title: String = window_title(hwnd);
        update_window_title(hwnd.0 as isize, title);
        debug_dump_windows();
    } else if matches!(event, EVENT_OBJECT_HIDE | EVENT_OBJECT_DESTROY | EVENT_OBJECT_CLOAKED) {
        // Remove window
        remove_window(hwnd.0 as isize);
        debug_dump_windows();
    }
}

/// Name: add_window
/// Purpose: Add a window to the window list.
fn add_window(hwnd: isize, pid: u32, title: String) {
    let mut map: MutexGuard<HashMap<WindowKey, WindowEntry>> = windows_map().lock().unwrap();
    (&mut *map).insert(hwnd, WindowEntry { pid, title });
}

/// Name: update_window_title
/// Purpose: Update a window title in the window list.
fn update_window_title(hwnd: isize, new_title: String) {
    let mut map: MutexGuard<HashMap<WindowKey, WindowEntry>> = windows_map().lock().unwrap();
    if let Some(entry) = (&mut *map).get_mut(&hwnd) {
        entry.title = new_title;
    }
}

/// Name: remove_window
/// Purpose: Remove a window from the window list.
fn remove_window(hwnd: isize) {
    let mut map: MutexGuard<HashMap<WindowKey, WindowEntry>> = windows_map().lock().unwrap();
    (&mut *map).remove(&hwnd);
}

/// Name: window_title
/// Purpose: Return the title of a window given a window handle.
fn window_title(hwnd: HWND) -> String {
    unsafe {
        let len = GetWindowTextLengthW(hwnd);
        if len == 0 {
            return String::new();
        }
        let mut buf = vec![0u16; len as usize + 1];
        let written = GetWindowTextW(hwnd, &mut buf);
        buf.truncate(written as usize);
        OsString::from_wide(&buf).to_string_lossy().into_owned()
    }
}

/// Name: debug_dump_windows
/// Purpose: Print the current contents of the window list.
pub fn debug_dump_windows() {
    // Take a stable snapshot of the window list
    let snapshot: Vec<(WindowKey, WindowEntry)> = {
        let map: MutexGuard<HashMap<WindowKey, WindowEntry>> = windows_map().lock().unwrap();
        map.iter().map(|(&k, v)| (k, v.clone())).collect()
    };

    // Sort entries
    let mut rows: Vec<(WindowKey, WindowEntry)> = snapshot;
    (&mut *rows).sort_by(|a, b| a.1.pid.cmp(&b.1.pid).then(a.0.cmp(&b.0)));

    // Timestamp
    let ts: String = Local::now().format("%Y-%m-%d %H:%M:%S%.3f").to_string();

    // Print Table Header
    println!(
        "WinApps Monitor Window List - {} Entr{} - Last Refresh: {}\r\n",
        rows.len(),
        if rows.len() == 1 { "y" } else { "ies" },
        ts
    );
    println!("{:<14} {:<8} {}", "HWND", "PID", "TITLE");
    println!("{:-<14} {:-<8} {:-<80}", "", "", "");

    // Print rows with aligned columns
    for (hwnd, entry) in rows {
        println!(
            "{:<14} {:<8} {}",
            format!("{:#x}", hwnd),
            entry.pid,
            truncate(&entry.title, 80)
        );
    }

    // Closing horizontal rule
    let total_width = 14 + 1 + 8 + 1 + 80; // widths + spaces
    println!("{:-<1$}", "", total_width);
    println!();
}

fn main() -> Result<()> {
    // Display System Tray Icon
    let icon = icon_from_ico();
    let _tray_icon = TrayIconBuilder::new()
        .with_tooltip("WinApps Monitor")
        .with_icon(icon)
        .build()?;

    // Flags:
    // - Call the callback function from outside the target application's process
    // - Suppress events originating from this process
    let flags: u32 = WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS;

    // Install hooks for the specific events we care about
    let hook_create: HWINEVENTHOOK    = unsafe { SetWinEventHook(EVENT_OBJECT_CREATE,    EVENT_OBJECT_CREATE,    None, Some(on_win_event), 0, 0, flags) };
    let hook_show: HWINEVENTHOOK      = unsafe { SetWinEventHook(EVENT_OBJECT_SHOW,      EVENT_OBJECT_SHOW,      None, Some(on_win_event), 0, 0, flags) };
    let hook_hide: HWINEVENTHOOK      = unsafe { SetWinEventHook(EVENT_OBJECT_HIDE,      EVENT_OBJECT_HIDE,      None, Some(on_win_event), 0, 0, flags) };
    let hook_destroy: HWINEVENTHOOK   = unsafe { SetWinEventHook(EVENT_OBJECT_DESTROY,   EVENT_OBJECT_DESTROY,   None, Some(on_win_event), 0, 0, flags) };
    let hook_cloaked: HWINEVENTHOOK   = unsafe { SetWinEventHook(EVENT_OBJECT_CLOAKED,   EVENT_OBJECT_CLOAKED,   None, Some(on_win_event), 0, 0, flags) };
    let hook_uncloaked: HWINEVENTHOOK = unsafe { SetWinEventHook(EVENT_OBJECT_UNCLOAKED, EVENT_OBJECT_UNCLOAKED, None, Some(on_win_event), 0, 0, flags) };

    // Hook verification (non-null handles mean success)
    println!("WINDOW HOOKS INSTALLED:");
    println!("- CREATE    = {}", (!hook_create.0.is_null()).to_string().to_uppercase());
    println!("- SHOW      = {}", (!hook_show.0.is_null()).to_string().to_uppercase());
    println!("- HIDE      = {}", (!hook_hide.0.is_null()).to_string().to_uppercase());
    println!("- DESTROY   = {}", (!hook_destroy.0.is_null()).to_string().to_uppercase());
    println!("- CLOAKED   = {}", (!hook_cloaked.0.is_null()).to_string().to_uppercase());
    println!("- UNCLOAKED = {}", (!hook_uncloaked.0.is_null()).to_string().to_uppercase());
    println!();

    // Seed the current state so already-open windows are present
    seed_open_windows();

    // Dump once to see the baseline state
    debug_dump_windows();

    // Keep the app alive AND pump messages so WinEvent callbacks can be delivered
    unsafe {
        let mut msg: MSG = MSG::default();
        // GetMessageW returns >0 until WM_QUIT; 0 on WM_QUIT; <0 on error.
        while GetMessageW(&mut msg, None, 0, 0).into() {
            let _ = TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }

    // TODO Unreachable - Need to implement unhook on shutdown
    #[allow(unreachable_code)]
    unsafe {
        if !hook_create.0.is_null()    { let _ = UnhookWinEvent(hook_create); }
        if !hook_show.0.is_null()      { let _ = UnhookWinEvent(hook_show); }
        if !hook_hide.0.is_null()      { let _ = UnhookWinEvent(hook_hide); }
        if !hook_destroy.0.is_null()   { let _ = UnhookWinEvent(hook_destroy); }
        if !hook_cloaked.0.is_null()   { let _ = UnhookWinEvent(hook_cloaked); }
        if !hook_uncloaked.0.is_null() { let _ = UnhookWinEvent(hook_uncloaked); }
    }

    Ok(())
}

/// Name:    is_application_frame_window
/// Purpose: Returns 'true' if the given window belongs to the UWP ApplicationFrameHost. This is
///          important to check, as UWP applications run under ApplicationFrameHost and need to be
///          enumerated differently.
/// Input:   Window Handle (HWND)
/// Output:  Boolean (True if UWP application, false if not)
fn is_application_frame_window(hwnd: HWND) -> bool {
    let mut buf = [0u16; 128];
    unsafe {
        let len = GetClassNameW(hwnd, &mut buf) as usize;
        if len == 0 {
            return false;
        }
        let class_name = String::from_utf16_lossy(&buf[..len]);
        class_name == "ApplicationFrameWindow"
    }
}

/// Name:    is_candidate_window
/// Purpose: Given a window handle, this function decides (using a few heuristics) whether the
///          window is likely to be a user-facing main/top-level application window, excluding
///          tool palettes, dialogs, popups, hidden windows, etc.
/// Input:   Window Handle (HWND)
/// Output:  Boolean (True if window of interest, false if not)
fn is_candidate_window(hwnd: HWND) -> bool {
    unsafe {
        // Exclude windows that are not visible
        // Note: Minimised windows are considered visible - use IsIconic instead to exclude them
        if IsWindowVisible(hwnd).as_bool() == false {
            return false;
        }

        // Exclude tool windows (palette/floaters)
        let ex = GetWindowLongPtrW(hwnd, GWL_EXSTYLE) as u32;
        if (ex & WS_EX_TOOLWINDOW.0) != 0 {
            return false;
        }

        // Detect common UWP host frame class
        let is_uwp_frame = is_application_frame_window(hwnd);

        // Prefer top-level (no owner) to exclude popups/dialogs attached to a parent window, BUT:
        // - Allow windows that explicitly ask for taskbar presence (WS_EX_APPWINDOW)
        // - Allow UWP frames even if they have an owner
        let root_owner: HWND = GetAncestor(hwnd, GA_ROOTOWNER);
        let has_appwindow: bool = (ex & WS_EX_APPWINDOW.0) != 0;
        if root_owner != hwnd && !has_appwindow && !is_uwp_frame {
            return false;
        }

        // Skip “hidden by owner” popups (Raymond Chen heuristic),
        // but keep UWP frames which can have quirky popup chains.
        let last_active_popup: HWND = GetLastActivePopup(hwnd);
        if !is_uwp_frame
            && last_active_popup != hwnd
            && !IsWindowVisible(last_active_popup).as_bool()
        {
            return false;
        }

        // Skip cloaked windows
        let mut cloaked: u32 = 0;
        let _ = DwmGetWindowAttribute(
            hwnd,
            DWMWA_CLOAKED,
            &mut cloaked as *mut _ as *mut _,
            size_of::<u32>() as u32,
        );
        if cloaked != 0 {
            return false;
        }
    }
    true
}

/// Name: seed_open_windows
/// Purpose: Enumerate current top-level windows and add them to WINDOWS.
fn seed_open_windows() {
    unsafe {
        // Write straight into the global map
        let _ = EnumWindows(Some(enum_windows_seed_proc), LPARAM(0));
    }
}

/// Name: enum_windows_seed_proc
/// Purpose: Enumerate current top-level windows and add them to WINDOWS.
extern "system" fn enum_windows_seed_proc(hwnd: HWND, _lparam: LPARAM) -> BOOL {
    // Apply the same filters used in the hook callback
    if !is_candidate_window(hwnd) {
        return BOOL(1);
    }

    // Store title
    let title = window_title(hwnd);

    // Resolve true PID (handles ApplicationFrameWindow/UWP)
    let pid = if is_application_frame_window(hwnd) {
        uwp_pid(hwnd)
    } else {
        let mut p = 0u32;
        unsafe { GetWindowThreadProcessId(hwnd, Some(&mut p)); }
        p
    };
    if pid == 0 {
        return BOOL(1);
    }

    // Insert into the map keyed by hWnd
    add_window(hwnd.0 as isize, pid, title);

    BOOL(1) // Continue enumeration
}

/// Name: enum_child_find_different_pid
/// Purpose: Discover the real/true process ID behind a 'modern' UWP window.
extern "system" fn enum_child_find_different_pid(hwnd: HWND, lparam: LPARAM) -> BOOL {
    unsafe {
        let ctx: &mut UwpPidSearch = &mut *(lparam.0 as *mut UwpPidSearch);
        let mut child_pid = 0u32;
        GetWindowThreadProcessId(hwnd, Some(&mut child_pid));

        if child_pid != 0 && child_pid != ctx.frame_pid {
            ctx.found_pid.set(child_pid);
            return BOOL(0); // Stop enumeration
        }
    }
    BOOL(1) // Continue
}

/// Name: uwp_pid
/// Rationale: The top-level frame window for 'modern' UWP applications is owned by the host process
///            'ApplicationFrameWindow'. Additional logic is required to identify the 'true' process
///            ID since the application content lives within a child window belonging to a different
///            process.
fn uwp_pid(hwnd: HWND) -> u32 {
    unsafe {
        let mut frame_pid: u32 = 0u32;
        GetWindowThreadProcessId(hwnd, Some(&mut frame_pid));
        let found: Cell<u32> = Cell::new(0u32);
        let mut ctx = UwpPidSearch {
            frame_pid,
            found_pid: &found,
        };

        let _ = EnumChildWindows(
            Some(hwnd),
            Some(enum_child_find_different_pid),
            LPARAM(&mut ctx as *mut _ as isize),
        );

        let pid: u32 = found.get();
        if pid != 0 { pid } else { frame_pid }
    }
}

/// Name: truncate
/// Purpose: For tidy console output.
fn truncate(s: &str, max: usize) -> String {
    if s.len() <= max {
        s.to_string()
    } else {
        let mut t = s.chars().take(max.saturating_sub(1)).collect::<String>();
        t.push('…');
        t
    }
}

/// Name: icon_from_ico
/// Purpose: Embed and prepare the system tray icon for use.
fn icon_from_ico() -> Icon {
    // Embed ICO at compile time
    let bytes = include_bytes!("../assets/icons/system_tray_icon.ico");

    // Process .ico file -> Pick the highest resolution -> Convert to RGBA
    let mut cursor = std::io::Cursor::new(&bytes[..]);
    let dir = ico::IconDir::read(&mut cursor).expect("Invalid .ico");
    let best = dir.entries()
        .iter()
        .max_by_key(|e| (e.width(), e.height(), e.bits_per_pixel()))
        .expect("No entries in .ico");
    let image = best.decode().expect("Failed to decode .ico image");
    let width = image.width();
    let height = image.height();
    let rgba = image.rgba_data().to_vec(); // RGBA8

    // Return the RGBA Icon
    Icon::from_rgba(rgba, width, height).expect("tray_icon::Icon::from_rgba failed")
}
