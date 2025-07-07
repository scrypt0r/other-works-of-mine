import os

def remove_duplicate_mkvs(root_path):
    successes = 0
    failures = 0

    for dirpath, dirnames, filenames in os.walk(root_path):
        mp4_files = {os.path.splitext(f)[0] for f in filenames if f.lower().endswith('.mp4')}
        
        for name in mp4_files:
            mkv_file = os.path.join(dirpath, name + '.mkv')
            
            if os.path.exists(mkv_file):
                try:
                    os.remove(mkv_file)
                    
                    print(f"Deleted: {name + '.mkv'}")
                    
                    successes += 1
                except Exception as e:
                    failures += 1
                    
                    print(f"Error deleting {mkv_file}: {e}")
    
    return successes, failures

if __name__ == "__main__":
    path = input("Enter the path to search for .mp4/.mkv files: ").strip()
    
    if os.path.isdir(path):
        print("Path found, deleting files...")
        
        successes, failures = remove_duplicate_mkvs(path)
        
        print(f"Successfully deleted {successes} .mkv file(s), with {failures} deletion failure(s).")
    else:
        print("Invalid path provided.")