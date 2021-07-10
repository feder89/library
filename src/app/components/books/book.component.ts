import { Component, OnInit } from '@angular/core';
import { MessageService } from 'primeng/components/common/messageservice';
import { Book } from 'src/app/interfaces/book';
import { BookService } from 'src/app/services/book.service';
import { AppComponent } from 'src/app/app.component';

@Component({
  selector: 'app-book',
  templateUrl: './book.component.html',
  styleUrls: ['./book.component.css']
})
export class BookComponent implements OnInit {
  public books: Book[];
  public displayDetailDialog: boolean;
  public bookIdSeleted: number = null;
  private totalBooks: Book[] = [];

  public type: string = null;
  public value: string = null;
  private idToDelete: number = 0;

  constructor(private bookService: BookService, private messageService: MessageService, private app: AppComponent) { }

  ngOnInit() {
    this.getAllBooks();
  }

  private getAllBooks() {
    this.bookService.getBooks().subscribe(
      (res: Book[]) => {
        this.books = res;
        this.totalBooks = res;
      }
    );
  }

  closeDialog(): void {
    this.getAllBooks();
    this.bookIdSeleted = -1;
  }

  onSelectBook(id: number): void {
    this.bookIdSeleted = id;
    this.displayDetailDialog = true;
  }

  onDeleteBook(id: number, titolo: string): void {
    this.idToDelete = id;
    this.value = titolo;
    this.type = "Libro";
  }

  confirmDelete(evt) {
    if (evt == true) {
      this.bookService.deleteBook(this.idToDelete).subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Libro rimosso');
          this.getAllBooks();
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
    }
    this.value = null;
    this.idToDelete = 0;
    this.type = null;
  }

  onAddBook(): void {
    this.bookIdSeleted = null;
    this.displayDetailDialog = true;
  }

  public filterBooks(s: string) {
    this.books = this.totalBooks.filter((b) => {
      return b.titolo.toLowerCase().indexOf(s) > -1;
    })
  }

}
