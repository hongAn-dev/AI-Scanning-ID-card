class StringUtils {
  static String removeDiacritics(String str) {
    const source =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐ';
    const dest =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydd';

    // Helper map for faster lookup
    for (int i = 0; i < source.length; i++) {
      str = str.replaceAll(source[i], dest[i]);
    }
    return str;
  }

  static bool containsIgnoreCase(String? source, String? query) {
    if (source == null || query == null) return false;
    final cleanSource = removeDiacritics(source.toLowerCase());
    final cleanQuery = removeDiacritics(query.toLowerCase());
    return cleanSource.contains(cleanQuery);
  }

  static bool equalsIgnoreCase(String? source, String? query) {
    if (source == null || query == null) return false;
    final cleanSource = removeDiacritics(source.toLowerCase());
    final cleanQuery = removeDiacritics(query.toLowerCase());
    return cleanSource == cleanQuery;
  }
}
