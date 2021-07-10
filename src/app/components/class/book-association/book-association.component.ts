import { Component, Input, OnChanges, SimpleChanges, OnInit } from '@angular/core';
import { ClassesService } from 'src/app/services/classes.service';
import { AppComponent } from 'src/app/app.component';
import { BookService } from 'src/app/services/book.service';
import { Book } from 'src/app/interfaces/book';
import * as _ from 'lodash';

@Component({
  selector: 'app-book-association',
  templateUrl: './book-association.component.html',
  styleUrls: ['./book-association.component.css']
})
export class BookAssociationComponent implements OnChanges {

  @Input() classId: number;
  public associated: any[] = [];
  public notAssociated: any[] = [];
  private allBooks: any[];
  private oldAssociated: any[];

  constructor(private classService: ClassesService, private app: AppComponent, private bookService: BookService) { }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['classId'] && changes['classId'].currentValue != null) {
      this.loadBooks(changes['classId'].currentValue);

    }
  }

  private loadBooks(classId: number): void {
    this.bookService.getBooks()
      .subscribe(
        (res: Book[]) => {
          this.allBooks = [];
          for (let i = 0; i < res.length; i++) {
            this.allBooks.push({
              id: res[i].id,
              casa_editrice: res[i].case_editrici.nome,
              titolo: res[i].titolo,
              materia: res[i].materia,
              isbn: res[i].codice_isbn
            });
          }
          this.loadAssociatedBook(classId);
          this.loadNotAssociatedBook(classId);
        }
      );
  }


  private loadAssociatedBook(classId: number): void {
    this.classService.getBookAssociationByClassId(classId)
      .subscribe(
        res => {
          this.associated = [];
          for (let i = 0; i < res.length; i++) {
            this.associated.push(this.allBooks.find(b => b.id === res[i].id));
          }
          this.oldAssociated = this.associated.slice();
        }
      );
  }

  private loadNotAssociatedBook(classId: number): void {
    this.classService.getBookNotAssociatedByClassId(classId)
      .subscribe(
        res => {
          this.notAssociated = [];
          for (let i = 0; i < res.length; i++) {
            this.notAssociated.push(this.allBooks.find(b => b.id === res[i].id));
          }
        }
      );
  }

  save(): void {
    const toBeDeleted = _.difference(this.oldAssociated, this.associated);
    const toBeAssociated = _.difference(this.associated, this.oldAssociated);

    toBeDeleted.forEach(el => {
      this.classService.deleteOldAssociations(el.id, this.classId)
        .subscribe(
          res => {
            this.app.handleToastMessages('success', 'Completato', 'Associazione rimossa');
          },
          error => {
            this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
          }
        );
    });
    toBeAssociated.forEach(el => {
      this.classService.createAssociations(el.id, this.classId)
        .subscribe(
          res => {
            this.app.handleToastMessages('success', 'Completato', 'Associazione creata');
          },
          error => {
            this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
          }
        );
    });
  }

}
